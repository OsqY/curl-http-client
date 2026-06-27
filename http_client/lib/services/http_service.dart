import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http_client/models/models.dart';
import 'package:http_client/services/cookie_jar.dart';
import 'package:http_client/utils/utils.dart';

/// Result of executing an HTTP request.
class HttpExecutionResult {
  final HttpResponse? response;
  final String? error;

  const HttpExecutionResult({this.response, this.error});
}

/// Service responsible for sending HTTP requests.
class HttpService {
  final CookieJar cookieJar;
  final Duration defaultTimeout;

  HttpService({
    required this.cookieJar,
    this.defaultTimeout = const Duration(seconds: 30),
  });

  /// Executes [request] with resolved values.
  Future<HttpExecutionResult> execute(
    HttpRequest request, {
    Map<String, String> variables = const {},
    String? accessToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final resolvedUrl = substituteInUrl(request.url, variables);
      final uri = Uri.parse(_addQueryParams(resolvedUrl, request.queryParams, variables));

      // Resolve headers.
      final headers = _resolveHeaders(request, variables, accessToken);

      // Resolve body.
      final body = _resolveBody(request, variables);

      // Create IO HTTP request to handle cookies/redirects manually.
      final ioClient = HttpClient();
      ioClient.connectionTimeout = defaultTimeout;

      final ioRequest = await ioClient.openUrl(request.method.name, uri);
      headers.forEach(ioRequest.headers.set);

      // Attach cookies for this domain.
      final cookies = cookieJar.cookiesFor(uri);
      if (cookies.isNotEmpty) {
        ioRequest.headers.set('Cookie', cookies.map((c) => '${c.name}=${c.value}').join('; '));
      }

      // Write body.
      if (body != null) {
        if (body is String) {
          ioRequest.write(body);
        } else if (body is List<int>) {
          ioRequest.add(Uint8List.fromList(body));
        }
      }

      final ioResponse = await ioRequest.close();
      final bytes = await _collectBytes(ioResponse);

      // Store cookies from response.
      cookieJar.storeFromResponse(uri, ioResponse);

      stopwatch.stop();

      final responseHeaders = <String, String>{};
      ioResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final response = HttpResponse(
        statusCode: ioResponse.statusCode,
        statusText: ioResponse.reasonPhrase,
        headers: responseHeaders,
        bodyBytes: bytes,
        durationMs: stopwatch.elapsedMilliseconds,
        receivedAt: DateTime.now(),
      );

      return HttpExecutionResult(response: response);
    } on SocketException catch (e) {
      return HttpExecutionResult(
        error: 'Connection error: ${e.osError?.message ?? e.message}',
      );
    } on HttpException catch (e) {
      return HttpExecutionResult(error: 'HTTP error: ${e.message}');
    } on FormatException catch (e) {
      return HttpExecutionResult(error: 'Invalid URL: ${e.message}');
    } catch (e) {
      return HttpExecutionResult(error: 'Unexpected error: $e');
    } finally {
      stopwatch.stop();
    }
  }

  String _addQueryParams(
    String url,
    List<KeyValuePair> queryParams,
    Map<String, String> variables,
  ) {
    if (queryParams.where((p) => p.enabled).isEmpty) return url;
    final uri = Uri.parse(url);
    final params = <String, String>{};
    for (final param in queryParams) {
      if (!param.enabled) continue;
      params[substituteVariables(param.key, variables)] =
          substituteVariables(param.value, variables);
    }
    return uri.replace(queryParameters: {...uri.queryParameters, ...params}).toString();
  }

  Map<String, String> _resolveHeaders(
    HttpRequest request,
    Map<String, String> variables,
    String? accessToken,
  ) {
    final headers = <String, String>{};
    for (final h in request.headers) {
      if (!h.enabled) continue;
      headers[substituteVariables(h.key, variables)] =
          substituteVariables(h.value, variables);
    }

    final auth = request.auth;
    if (auth is BearerAuth && auth.token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${substituteVariables(auth.token, variables)}';
    } else if (auth is BasicAuth) {
      final credentials =
          base64Encode(utf8.encode('${auth.username}:${auth.password}'));
      headers['Authorization'] = 'Basic $credentials';
    } else if (auth is ApiKeyAuth) {
      if (auth.location == ApiKeyLocation.header) {
        headers[auth.key] = substituteVariables(auth.value, variables);
      }
    } else if (auth is OAuth2Auth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    // Ensure content-type for raw body.
    if (request.body.mode == BodyMode.raw && request.body.rawContent.isNotEmpty) {
      final contentType = request.body.rawContentType.mime;
      if (!headers.containsKey(HttpHeaders.contentTypeHeader)) {
        headers[HttpHeaders.contentTypeHeader] = contentType;
      }
    } else if (request.body.mode == BodyMode.urlEncoded) {
      headers[HttpHeaders.contentTypeHeader] = 'application/x-www-form-urlencoded';
    } else if (request.body.mode == BodyMode.formData) {
      headers[HttpHeaders.contentTypeHeader] = 'multipart/form-data';
    }

    return headers;
  }

  dynamic _resolveBody(HttpRequest request, Map<String, String> variables) {
    final body = request.body;
    switch (body.mode) {
      case BodyMode.none:
      case BodyMode.binary:
        return null;
      case BodyMode.raw:
        final text = substituteVariables(body.rawContent, variables);
        if (text.isEmpty) return null;
        return text;
      case BodyMode.urlEncoded:
        final pairs = body.formData.where((p) => p.enabled).map((p) =>
            '${Uri.encodeComponent(substituteVariables(p.key, variables))}='
            '${Uri.encodeComponent(substituteVariables(p.value, variables))}');
        if (pairs.isEmpty) return null;
        return pairs.join('&');
      case BodyMode.formData:
        return _buildMultipartBody(body.formData, variables);
    }
  }

  List<int> _buildMultipartBody(
    List<KeyValuePair> formData,
    Map<String, String> variables,
  ) {
    final boundary = '----HttpClientBoundary${DateTime.now().millisecondsSinceEpoch}';
    final buffer = BytesBuilder();
    for (final field in formData.where((p) => p.enabled)) {
      buffer.add(utf8.encode('--$boundary\r\n'));
      buffer.add(utf8.encode(
          'Content-Disposition: form-data; name="${substituteVariables(field.key, variables)}"\r\n\r\n'));
      buffer.add(utf8.encode('${substituteVariables(field.value, variables)}\r\n'));
    }
    buffer.add(utf8.encode('--$boundary--\r\n'));
    return buffer.toBytes();
  }

  Future<Uint8List> _collectBytes(HttpClientResponse response) async {
    final chunks = <List<int>>[];
    await for (final chunk in response) {
      chunks.add(chunk);
    }
    final totalLength = chunks.fold(0, (sum, c) => sum + c.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }
}
