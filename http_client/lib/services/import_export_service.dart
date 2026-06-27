import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'package:http_client/models/models.dart';

// ---------------------------------------------------------------------------
// CurlParser
// ---------------------------------------------------------------------------

/// Parses a curl command string into an [HttpRequest].
class CurlParser {
  /// Parses [command] (a single curl invocation) and returns the equivalent
  /// [HttpRequest].
  ///
  /// Supported flags:
  ///   -X / --request, -H / --header, -d / --data / --data-raw,
  ///   --data-urlencode, -u / --user, -b / --cookie, -F / --form,
  ///   --url, positional URL argument
  ///
  /// Throws [ArgumentError] if the command cannot be parsed.
  static HttpRequest parse(String command) {
    final tokens = _tokenize(command);
    if (tokens.isEmpty) {
      throw ArgumentError('Curl command is empty');
    }

    int i = 0;
    if (tokens[0].toLowerCase() == 'curl') i = 1;

    HttpMethod method = HttpMethod.get;
    final headers = <KeyValuePair>[];
    AuthConfig auth = const NoAuth();
    String? url;
    bool hasDataFlag = false;

    String rawBody = '';
    final urlEncodedPairs = <KeyValuePair>[];
    final formPairs = <KeyValuePair>[];

    while (i < tokens.length) {
      final token = tokens[i];

      if (token == '-X' || token == '--request') {
        i++;
        if (i < tokens.length) {
          method = HttpMethod.fromName(tokens[i]);
        }
      } else if (token == '-H' || token == '--header') {
        i++;
        if (i < tokens.length) {
          final header = tokens[i];
          final colonIdx = header.indexOf(':');
          if (colonIdx > 0) {
            final key = header.substring(0, colonIdx).trim();
            final value = header.substring(colonIdx + 1).trim();

            // Detect Bearer auth from Authorization header
            if (key.toLowerCase() == 'authorization') {
              if (value.toLowerCase().startsWith('bearer ')) {
                auth = BearerAuth(token: value.substring(7).trim());
                i++;
                continue;
              }
            }

            headers.add(KeyValuePair(key: key, value: value));
          }
        }
      } else if (token == '-d' || token == '--data' || token == '--data-raw') {
        i++;
        if (i < tokens.length) {
          hasDataFlag = true;
          if (method == HttpMethod.get) method = HttpMethod.post;
          if (rawBody.isNotEmpty) rawBody += '&';
          rawBody += tokens[i];
        }
      } else if (token == '--data-urlencode') {
        i++;
        if (i < tokens.length) {
          hasDataFlag = true;
          if (method == HttpMethod.get) method = HttpMethod.post;
          final raw = tokens[i];
          final eqIdx = raw.indexOf('=');
          if (eqIdx > 0) {
            urlEncodedPairs.add(KeyValuePair(
              key: raw.substring(0, eqIdx),
              value: raw.substring(eqIdx + 1),
            ));
          } else {
            urlEncodedPairs.add(KeyValuePair(key: '', value: raw));
          }
        }
      } else if (token == '-u' || token == '--user') {
        i++;
        if (i < tokens.length) {
          final userpass = tokens[i];
          final colonIdx = userpass.indexOf(':');
          if (colonIdx > 0) {
            auth = BasicAuth(
              username: userpass.substring(0, colonIdx),
              password: userpass.substring(colonIdx + 1),
            );
          }
        }
      } else if (token == '-b' || token == '--cookie') {
        i++;
        if (i < tokens.length) {
          headers.add(KeyValuePair(key: 'Cookie', value: tokens[i]));
        }
      } else if (token == '-F' || token == '--form') {
        i++;
        if (i < tokens.length) {
          hasDataFlag = true;
          if (method == HttpMethod.get) method = HttpMethod.post;
          final raw = tokens[i];
          final eqIdx = raw.indexOf('=');
          if (eqIdx > 0) {
            formPairs.add(KeyValuePair(
              key: raw.substring(0, eqIdx),
              value: raw.substring(eqIdx + 1),
            ));
          }
        }
      } else if (token == '--url') {
        i++;
        if (i < tokens.length) {
          url = tokens[i];
        }
      } else if (!token.startsWith('-')) {
        // Positional argument — treat as URL
        url ??= token;
      }

      i++;
    }

    if (url == null) {
      throw ArgumentError('No URL found in curl command');
    }

    // --- Build body --------------------------------------------------------
    RequestBody body = const RequestBody();
    if (hasDataFlag) {
      if (urlEncodedPairs.isNotEmpty) {
        body = RequestBody(
          mode: BodyMode.urlEncoded,
          formData: urlEncodedPairs,
        );
      } else if (formPairs.isNotEmpty) {
        body = RequestBody(
          mode: BodyMode.formData,
          formData: formPairs,
        );
      } else if (rawBody.isNotEmpty) {
        body = _buildBodyFromRaw(rawBody, headers);
      }
    }

    // --- Extract query params from URL ------------------------------------
    final uri = Uri.tryParse(url);
    List<KeyValuePair> queryParams = [];
    String cleanUrl = url;
    if (uri != null && uri.hasQuery) {
      queryParams = uri.queryParametersAll.entries
          .expand((e) => e.value.map((v) => KeyValuePair(key: e.key, value: v)))
          .toList();
      cleanUrl = url.replaceFirst('?${uri.query}', '');
    }

    return HttpRequest(
      id: HttpRequest.generateId(),
      name: 'Imported',
      method: method,
      url: cleanUrl,
      headers: headers,
      queryParams: queryParams,
      body: body,
      auth: auth,
    );
  }

  /// Determines body mode and content type from raw body string and headers.
  static RequestBody _buildBodyFromRaw(
    String rawBody,
    List<KeyValuePair> headers,
  ) {
    final ct = _getContentTypeHeader(headers);

    // JSON via Content-Type header
    if (ct == 'application/json') {
      return RequestBody(
        mode: BodyMode.raw,
        rawContent: rawBody,
        rawContentType: RawContentType.json,
      );
    }

    // XML via Content-Type header
    if (ct == 'application/xml' || ct == 'text/xml') {
      return RequestBody(
        mode: BodyMode.raw,
        rawContent: rawBody,
        rawContentType: RawContentType.xml,
      );
    }

    // URL-encoded via Content-Type header
    if (ct == 'application/x-www-form-urlencoded') {
      return RequestBody(
        mode: BodyMode.urlEncoded,
        formData: _parseFormUrlEncoded(rawBody),
      );
    }

    // Auto-detect if no Content-Type is set
    if (_looksLikeJson(rawBody)) {
      return RequestBody(
        mode: BodyMode.raw,
        rawContent: rawBody,
        rawContentType: RawContentType.json,
      );
    }

    if (_looksLikeFormUrlEncoded(rawBody)) {
      return RequestBody(
        mode: BodyMode.urlEncoded,
        formData: _parseFormUrlEncoded(rawBody),
      );
    }

    // Fallback: raw text
    return RequestBody(
      mode: BodyMode.raw,
      rawContent: rawBody,
      rawContentType: RawContentType.text,
    );
  }

  /// Returns the value (lower-cased, media-type only) of the Content-Type
  /// header if present, or `null`.
  static String? _getContentTypeHeader(List<KeyValuePair> headers) {
    for (final h in headers) {
      if (h.key.toLowerCase() == 'content-type') {
        return h.value.toLowerCase().split(';').first.trim();
      }
    }
    return null;
  }

  /// Returns `true` if [data] looks like JSON (starts with `{` or `[`).
  static bool _looksLikeJson(String data) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return false;
    final first = trimmed[0];
    return first == '{' || first == '[';
  }

  /// Returns `true` if [data] looks like URL-encoded form data (contains `=`
  /// and `&`, or is a single `key=value` pair).
  static bool _looksLikeFormUrlEncoded(String data) {
    if (!data.contains('=')) return false;
    // A single key=value is valid url-encoded data
    return true;
  }

  /// Splits URL-encoded [data] into [KeyValuePair] entries, URL-decoding
  /// both keys and values.
  static List<KeyValuePair> _parseFormUrlEncoded(String data) {
    final pairs = <KeyValuePair>[];
    for (final part in data.split('&')) {
      if (part.isEmpty) continue;
      final eqIdx = part.indexOf('=');
      if (eqIdx > 0) {
        pairs.add(KeyValuePair(
          key: Uri.decodeQueryComponent(part.substring(0, eqIdx)),
          value: Uri.decodeQueryComponent(part.substring(eqIdx + 1)),
        ));
      } else {
        pairs.add(KeyValuePair(
          key: Uri.decodeQueryComponent(part),
          value: '',
        ));
      }
    }
    return pairs;
  }

  /// Shell-like tokenizer that respects single and double quotes and basic
  /// backslash escaping.
  static List<String> _tokenize(String cmd) {
    final tokens = <String>[];
    final buf = StringBuffer();
    bool inSingle = false;
    bool inDouble = false;

    for (int i = 0; i < cmd.length; i++) {
      final c = cmd[i];

      // Toggle single-quote mode
      if (c == "'" && !inDouble) {
        inSingle = !inSingle;
        continue;
      }

      // Toggle double-quote mode
      if (c == '"' && !inSingle) {
        inDouble = !inDouble;
        continue;
      }

      // Escape sequence inside double quotes: \, ", $
      if (c == '\\' && inDouble && i + 1 < cmd.length) {
        i++;
        buf.write(cmd[i]);
        continue;
      }

      // Escape sequence outside quotes
      if (c == '\\' && !inSingle && !inDouble && i + 1 < cmd.length) {
        i++;
        buf.write(cmd[i]);
        continue;
      }

      // Whitespace separates tokens outside quotes
      if ((c == ' ' || c == '\t') && !inSingle && !inDouble) {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
        continue;
      }

      buf.write(c);
    }

    if (buf.isNotEmpty) {
      tokens.add(buf.toString());
    }

    return tokens;
  }
}

// ---------------------------------------------------------------------------
// OpenApiImporter
// ---------------------------------------------------------------------------

/// Result holder returned by [OpenApiImporter.import].
class ImportResult {
  final RequestCollection collection;
  final List<HttpRequest> requests;

  const ImportResult({required this.collection, required this.requests});
}

/// Parses an OpenAPI 3.x specification (JSON or YAML) into a
/// [RequestCollection] plus a list of [HttpRequest]s.
class OpenApiImporter {
  /// Parses OpenAPI content from [content] string.
  ///
  /// Set [isYaml] to `true` (default) for YAML input, `false` for JSON.
  /// Returns an [ImportResult] containing the collection and requests.
  static ImportResult import(String content, {bool isYaml = true}) {
    // Parse
    final raw = isYaml ? loadYaml(content) : jsonDecode(content);
    final spec = _toPlain(raw) as Map<String, dynamic>;

    final info = spec['info'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final collectionTitle = info['title'] as String? ?? 'Imported API';

    // Servers
    final servers = spec['servers'] as List<dynamic>? ?? [];
    final baseUrl = servers.isNotEmpty
        ? (servers.first as Map<String, dynamic>)['url'] as String? ?? ''
        : '';

    final paths = spec['paths'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final requests = <HttpRequest>[];

    final methodNames = [
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'head',
      'options',
    ];

    for (final pathEntry in paths.entries) {
      final path = pathEntry.key;
      final operations = pathEntry.value as Map<String, dynamic>;

      for (final methodName in methodNames) {
        if (!operations.containsKey(methodName)) continue;

        final operation = operations[methodName] as Map<String, dynamic>;
        final request =
            _buildRequest(baseUrl, path, methodName, operation);
        if (request != null) {
          requests.add(request);
        }
      }
    }

    final collection = RequestCollection(
      id: HttpRequest.generateId(),
      name: collectionTitle,
      description: info['description'] as String?,
    );

    return ImportResult(collection: collection, requests: requests);
  }

  /// Creates an [HttpRequest] from an OpenAPI path + operation entry.
  static HttpRequest? _buildRequest(
    String baseUrl,
    String path,
    String methodName,
    Map<String, dynamic> operation,
  ) {
    final operationId = operation['operationId'] as String?;
    final summary = operation['summary'] as String?;
    final name = operationId ??
        summary ??
        '${methodName.toUpperCase()} $path';

    final method = HttpMethod.fromName(methodName.toUpperCase());
    final url = '$baseUrl$path';

    final headers = <KeyValuePair>[];
    final queryParams = <KeyValuePair>[];

    // Extract parameters
    final params = operation['parameters'] as List<dynamic>? ?? [];
    for (final p in params) {
      final param = p as Map<String, dynamic>;
      final paramName = param['name'] as String? ?? '';
      final paramIn = param['in'] as String? ?? '';
      final paramValue = param['schema'] is Map
          ? ((param['schema'] as Map)['example'] as String? ?? '')
          : '';
      final kvp = KeyValuePair(key: paramName, value: paramValue);

      if (paramIn == 'query') {
        queryParams.add(kvp);
      } else if (paramIn == 'header') {
        headers.add(kvp);
      }
    }

    // Request body
    RequestBody body = const RequestBody();
    final requestBody = operation['requestBody'] as Map<String, dynamic>?;
    if (requestBody != null) {
      final content = requestBody['content'] as Map<String, dynamic>?;
      if (content != null && content.isNotEmpty) {
        final firstContentType = content.entries.first.key;
        headers.add(KeyValuePair(key: 'Content-Type', value: firstContentType));
      }
    }

    return HttpRequest(
      id: HttpRequest.generateId(),
      name: name,
      method: method,
      url: url,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

  /// Recursively converts YamlMap / YamlList to plain Dart types.
  static dynamic _toPlain(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toPlain(v)));
    } else if (value is List) {
      return value.map(_toPlain).toList();
    }
    return value;
  }
}

// ---------------------------------------------------------------------------
// CurlExporter
// ---------------------------------------------------------------------------

/// Exports a list of [HttpRequest]s as a shell script containing curl commands.
class CurlExporter {
  /// Generates a shell script string. Each request produces one `curl` line.
  static String export(List<HttpRequest> requests) {
    final lines = <String>['#!/bin/bash', ''];
    for (final req in requests) {
      lines.add(_buildCurlCommand(req));
      lines.add('');
    }
    return lines.join('\n');
  }

  /// Builds a single curl command for [req].
  static String _buildCurlCommand(HttpRequest req) {
    final parts = <String>['curl', '-s'];

    // Method
    if (req.method != HttpMethod.get) {
      parts.add('-X');
      parts.add(req.method.name);
    }

    // URL with query parameters
    parts.add(_shQuote(_buildFullUrl(req)));

    // Headers
    for (final h in req.headers.where((h) => h.enabled)) {
      parts.add('-H');
      parts.add(_shQuote('${h.key}: ${h.value}'));
    }

    // Auth
    if (req.auth is BasicAuth) {
      final basic = req.auth as BasicAuth;
      parts.add('-u');
      parts.add(_shQuote('${basic.username}:${basic.password}'));
    } else if (req.auth is BearerAuth) {
      final bearer = req.auth as BearerAuth;
      parts.add('-H');
      parts.add(_shQuote('Authorization: Bearer ${bearer.token}'));
    }

    // Body
    if (req.body.mode == BodyMode.raw && req.body.rawContent.isNotEmpty) {
      parts.add('-d');
      parts.add(_shQuote(req.body.rawContent));
    } else if (req.body.mode == BodyMode.urlEncoded &&
        req.body.formData.isNotEmpty) {
      for (final f in req.body.formData.where((p) => p.enabled)) {
        parts.add('--data-urlencode');
        parts.add(_shQuote('${f.key}=${f.value}'));
      }
    } else if (req.body.mode == BodyMode.formData &&
        req.body.formData.isNotEmpty) {
      for (final f in req.body.formData.where((p) => p.enabled)) {
        parts.add('-F');
        parts.add(_shQuote('${f.key}=${f.value}'));
      }
    }

    return parts.join(' ');
  }

  /// Builds the full URL including query parameters.
  static String _buildFullUrl(HttpRequest req) {
    if (req.queryParams.isEmpty) return req.url;

    final uri = Uri.tryParse(req.url);
    if (uri == null) return req.url;

    final queryMap = <String, String>{};
    for (final qp in req.queryParams.where((p) => p.enabled)) {
      queryMap[qp.key] = qp.value;
    }
    return uri.replace(queryParameters: queryMap).toString();
  }

  /// Shell-safe single- or double-quote wrapping.
  static String _shQuote(String s) {
    if (!s.contains("'") && !s.contains('\n')) {
      return "'$s'";
    }
    // Fall back to double-quote with escaping
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    return '"$escaped"';
  }
}

// ---------------------------------------------------------------------------
// OpenApiExporter
// ---------------------------------------------------------------------------

/// Exports a [RequestCollection] and its requests as an OpenAPI 3.0.0 JSON
/// string.
class OpenApiExporter {
  /// Produces a pretty-printed OpenAPI 3.0.0 JSON string from the given
  /// [collection] and [requests].
  static String export(
    RequestCollection collection,
    List<HttpRequest> requests,
  ) {
    final doc = _buildDocument(collection, requests);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(doc);
  }

  /// Builds the full OpenAPI document map.
  static Map<String, dynamic> _buildDocument(
    RequestCollection collection,
    List<HttpRequest> requests,
  ) {
    // Derive server URL from the first request
    final serverUrl = _deriveServerUrl(requests);

    return {
      'openapi': '3.0.0',
      'info': {
        'title': collection.name,
        'version': '1.0.0',
        if (collection.description != null)
          'description': collection.description,
      },
      'servers': [
        {'url': serverUrl},
      ],
      'paths': _buildPaths(requests),
    };
  }

  /// Derives a server base URL from the first request in [requests].
  static String _deriveServerUrl(List<HttpRequest> requests) {
    if (requests.isEmpty) return 'http://localhost';
    final uri = Uri.tryParse(requests.first.url);
    if (uri == null) return 'http://localhost';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Groups requests by their URL path and builds the OpenAPI `paths` object.
  static Map<String, dynamic> _buildPaths(List<HttpRequest> requests) {
    final Map<String, Map<String, HttpRequest>> grouped = {};

    for (final req in requests) {
      final uri = Uri.tryParse(req.url);
      String path;
      if (uri != null) {
        // Strip the server prefix to get a relative path
        final relUri = uri.path.isEmpty ? '/' : uri.path;
        path = relUri;
      } else {
        path = '/';
      }
      grouped.putIfAbsent(path, () => {});
      grouped[path]![req.method.name.toLowerCase()] = req;
    }

    final Map<String, dynamic> paths = {};
    for (final entry in grouped.entries) {
      final path = _normalizePath(entry.key);
      final operations = <String, dynamic>{};
      for (final methodEntry in entry.value.entries) {
        operations[methodEntry.key] =
            _buildOperation(methodEntry.value, methodEntry.key);
      }
      paths[path] = operations;
    }
    return paths;
  }

  /// Ensures path starts with `/`.
  static String _normalizePath(String p) {
    if (p.startsWith('/')) return p;
    return '/$p';
  }

  /// Builds a single OpenAPI operation object from [req].
  static Map<String, dynamic> _buildOperation(
    HttpRequest req,
    String method,
  ) {
    final parameters = <Map<String, dynamic>>[];

    // Query parameters
    for (final qp in req.queryParams.where((p) => p.enabled)) {
      parameters.add({
        'name': qp.key,
        'in': 'query',
        'schema': {'type': 'string'},
        if (qp.value.isNotEmpty) 'example': qp.value,
      });
    }

    // Header parameters (skip Content-Type — handled in requestBody)
    for (final hp in req.headers.where((p) => p.enabled)) {
      if (hp.key.toLowerCase() == 'content-type') continue;
      parameters.add({
        'name': hp.key,
        'in': 'header',
        'schema': {'type': 'string'},
        if (hp.value.isNotEmpty) 'example': hp.value,
      });
    }

    final operation = <String, dynamic>{
      'operationId': _toSafeOperationId(req.name),
      'summary': req.name,
      if (parameters.isNotEmpty) 'parameters': parameters,
    };

    // Request body
    if (req.body.mode != BodyMode.none) {
      operation['requestBody'] = _buildRequestBody(req);
    }

    // Placeholder responses
    operation['responses'] = {
      '200': {'description': 'Successful response'},
    };

    return operation;
  }

  /// Builds a `requestBody` object from [req]'s body.
  static Map<String, dynamic> _buildRequestBody(HttpRequest req) {
    String contentType;
    dynamic example;

    switch (req.body.mode) {
      case BodyMode.raw:
        contentType = req.body.rawContentType.mime;
        example = req.body.rawContent;
        break;
      case BodyMode.urlEncoded:
        contentType = 'application/x-www-form-urlencoded';
        if (req.body.formData.isNotEmpty) {
          example = req.body.formData
              .where((p) => p.enabled)
              .map((p) => '${p.key}=${p.value}')
              .join('&');
        }
        break;
      case BodyMode.formData:
        contentType = 'multipart/form-data';
        if (req.body.formData.isNotEmpty) {
          example = req.body.formData
              .where((p) => p.enabled)
              .map((p) => '${p.key}=${p.value}')
              .join('\n');
        }
        break;
      case BodyMode.none:
      case BodyMode.binary:
        contentType = 'application/octet-stream';
        break;
    }

    return {
      'content': {
        contentType: {
          'schema': {'type': 'string'},
          if (example != null && example.toString().isNotEmpty)
            'example': example,
        },
      },
    };
  }

  /// Converts [name] to a valid OpenAPI operationId (alphanumeric + underscore
  /// only).
  static String _toSafeOperationId(String name) {
    final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (safe.isEmpty) return 'operation';
    // Ensure it doesn't start with a digit
    if (RegExp(r'^[0-9]').hasMatch(safe)) return '_$safe';
    return safe;
  }
}

/// Convenience wrapper that exposes the import/export operations.
class ImportExportService {
  HttpRequest parseCurl(String command) => CurlParser.parse(command);

  ImportResult importOpenApi(String source, {bool isYaml = false}) =>
      OpenApiImporter.import(source, isYaml: isYaml);

  String exportCurl(List<HttpRequest> requests) => CurlExporter.export(requests);

  String exportOpenApi(RequestCollection collection, List<HttpRequest> requests) =>
      OpenApiExporter.export(collection, requests);
}
