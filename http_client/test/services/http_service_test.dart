import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/services/cookie_jar.dart';
import 'package:http_client/services/http_service.dart';

/// Starts a minimal HTTP server on a random port that responds to echo-style requests.
Future<HttpServer> _startEchoServer() async {
  final server = await HttpServer.bind('localhost', 0);
  server.listen((request) {
    request.response.statusCode = 200;
    request.response.headers.set('x-echo', 'true');
    request.response.headers.set('content-type', 'application/json');

    final echoHeaders = <String, String>{};
    request.headers.forEach((name, values) {
      echoHeaders[name] = values.join(', ');
    });

    request.toList().then((chunks) {
      final body = utf8.decode(chunks.expand((c) => c).toList());
      final echo = jsonEncode({
        'method': request.method,
        'uri': request.uri.toString(),
        'headers': echoHeaders,
        if (body.isNotEmpty) 'body': body,
      });
      request.response.write(echo);
      request.response.close();
    });
  });
  return server;
}

void main() {
  late CookieJar cookieJar;
  late HttpService service;

  setUp(() {
    cookieJar = CookieJar();
    service = HttpService(cookieJar: cookieJar);
  });

  group('HttpService', () {
    // ---- Request assembly (via execute against echo server) ----

    test('sends GET request with correct method and URL', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Get Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
        );

        final result = await service.execute(request);

        expect(result.error, isNull);
        expect(result.response, isNotNull);
        expect(result.response!.statusCode, 200);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['method'], 'GET');
        expect(body['uri'], '/echo');
      } finally {
        await server.close();
      }
    });

    test('sends custom headers', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Header Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
          headers: [
            const KeyValuePair(key: 'X-Custom', value: 'my-value'),
          ],
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['headers']['x-custom'], 'my-value');
      } finally {
        await server.close();
      }
    });

    test('sends Bearer auth as Authorization header', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Auth Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
          auth: BearerAuth(token: 'my-token'),
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['headers']['authorization'], 'Bearer my-token');
      } finally {
        await server.close();
      }
    });

    test('sends raw JSON body with Content-Type header', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Body Test',
          method: HttpMethod.post,
          url: 'http://localhost:$port/echo',
          body: const RequestBody(
            mode: BodyMode.raw,
            rawContent: '{"hello":"world"}',
            rawContentType: RawContentType.json,
          ),
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['method'], 'POST');
        expect(body['body'], '{"hello":"world"}');
        expect(body['headers']['content-type'], 'application/json');
      } finally {
        await server.close();
      }
    });

    test('sends query parameters appended to URL', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Query Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
          queryParams: [
            const KeyValuePair(key: 'page', value: '1'),
            const KeyValuePair(key: 'limit', value: '10'),
          ],
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['uri'], '/echo?page=1&limit=10');
      } finally {
        await server.close();
      }
    });

    test('sends disabled query parameters excluded from URL', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Query Filter Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
          queryParams: [
            const KeyValuePair(key: 'active', value: 'yes'),
            const KeyValuePair(key: 'disabled', value: 'no', enabled: false),
          ],
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['uri'], '/echo?active=yes');
        expect(body['uri'], isNot(contains('disabled')));
      } finally {
        await server.close();
      }
    });

    test('sends URL-encoded body', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Form Test',
          method: HttpMethod.post,
          url: 'http://localhost:$port/echo',
          body: const RequestBody(
            mode: BodyMode.urlEncoded,
            formData: [
              KeyValuePair(key: 'username', value: 'alice'),
              KeyValuePair(key: 'password', value: 'secret'),
            ],
          ),
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['method'], 'POST');
        expect(body['body'], 'username=alice&password=secret');
        expect(body['headers']['content-type'],
            'application/x-www-form-urlencoded');
      } finally {
        await server.close();
      }
    });

    // ---- Error handling ----

    test('returns error for unreachable host', () async {
      final timeoutService = HttpService(
        cookieJar: CookieJar(),
        defaultTimeout: const Duration(seconds: 2),
      );
      final request = HttpRequest(
        id: 'req-err',
        name: 'Unreachable Test',
        method: HttpMethod.get,
        url: 'http://localhost:1/nonexistent',
      );

      final result = await timeoutService.execute(request);

      expect(result.response, isNull);
      expect(result.error, isNotNull);
    });

    test('returns error for malformed URL', () async {
      final request = HttpRequest(
        id: 'req-err',
        name: 'Bad URL',
        method: HttpMethod.get,
        url: 'not a url at all',
      );

      final result = await service.execute(request);

      expect(result.response, isNull);
      expect(result.error, isNotNull);
    });

    // ---- Cookie handling ----

    test('sends cookies from jar matching request domain', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        cookieJar = CookieJar(cookies: [
          StoredCookie(
            name: 'session',
            value: 'abc123',
            domain: 'localhost',
          ),
        ]);
        service = HttpService(cookieJar: cookieJar);

        final request = HttpRequest(
          id: 'req-1',
          name: 'Cookie Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['headers']['cookie'], contains('session=abc123'));
      } finally {
        await server.close();
      }
    });

    test('does not send cookies for a different domain', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        cookieJar = CookieJar(cookies: [
          StoredCookie(
            name: 'session',
            value: 'abc123',
            domain: 'other.example.com',
          ),
        ]);
        service = HttpService(cookieJar: cookieJar);

        final request = HttpRequest(
          id: 'req-1',
          name: 'No Cookie Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
        );

        final result = await service.execute(request);

        final body = jsonDecode(result.response!.bodyText ?? '{}');
        expect(body['headers']['cookie'], isNull);
      } finally {
        await server.close();
      }
    });

    // ---- Response metadata ----

    test('captures response status code and headers', () async {
      final server = await _startEchoServer();
      try {
        final port = server.port;
        final request = HttpRequest(
          id: 'req-1',
          name: 'Response Test',
          method: HttpMethod.get,
          url: 'http://localhost:$port/echo',
        );

        final result = await service.execute(request);

        expect(result.response!.statusCode, 200);
        expect(result.response!.statusText, 'OK');
        expect(result.response!.headers['x-echo'], 'true');
        expect(result.response!.durationMs, greaterThan(0));
        expect(result.response!.sizeBytes, greaterThan(0));
      } finally {
        await server.close();
      }
    });
  });
}
