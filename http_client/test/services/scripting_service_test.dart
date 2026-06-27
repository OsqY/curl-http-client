import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/models/models.dart' as models;
import 'package:http_client/services/scripting_service.dart';

void main() {
  late ScriptingService service;
  late models.HttpRequest sampleRequest;
  late models.HttpResponse sampleResponse;

  setUp(() {
    service = ScriptingService();
    sampleRequest = models.HttpRequest(
      id: 'req-1',
      name: 'Test',
      method: models.HttpMethod.get,
      url: 'https://api.example.com/users',
      headers: [
        const models.KeyValuePair(key: 'Authorization', value: 'Bearer tok'),
      ],
      queryParams: [
        const models.KeyValuePair(key: 'page', value: '1'),
      ],
      body: const models.RequestBody(mode: models.BodyMode.none),
    );

    sampleResponse = models.HttpResponse(
      statusCode: 200,
      statusText: 'OK',
      headers: {'content-type': 'application/json'},
      bodyBytes: utf8.encode('{"id":1,"name":"Alice"}'),
      durationMs: 120,
      receivedAt: DateTime.now(),
    );
  });

  group('ScriptingService', () {
    test('runPreRequest sets a variable', () async {
      const script = "variables['token'] = variables['base_url']! + '/v1';";

      final ctx = await service.runPreRequest(
        script,
        sampleRequest,
        {'base_url': 'https://api.example.com'},
      );

      expect(ctx.variables['token'], 'https://api.example.com/v1');
      expect(ctx.variables['base_url'], 'https://api.example.com');
      expect(ctx.errors, isEmpty);
    });

    test('runPreRequest reads request details', () async {
      const script = '''
variables['full_url'] = request['url'] + '?page=' + (request['queryParams'] as Map)['page'];
''';

      final ctx = await service.runPreRequest(
        script,
        sampleRequest,
        {},
      );

      expect(
        ctx.variables['full_url'],
        'https://api.example.com/users?page=1',
      );
      expect(ctx.errors, isEmpty);
    });

    test('runPreRequest captures script errors', () async {
      const script = "throw Exception('oops');";

      final ctx = await service.runPreRequest(
        script,
        sampleRequest,
        {},
      );

      expect(ctx.errors, isNotEmpty);
      expect(ctx.errors.first, contains('oops'));
    });

    test('runPreRequest empty script does nothing', () async {
      const script = '';

      final ctx = await service.runPreRequest(
        script,
        sampleRequest,
        {'keep': 'me'},
      );

      expect(ctx.variables, {'keep': 'me'});
      expect(ctx.errors, isEmpty);
      expect(ctx.assertions, isEmpty);
    });

    test('runPostResponse asserts status code', () async {
      const script = "test('status is 200', response!['statusCode'] == 200);";

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {},
      );

      expect(ctx.assertions, contains('PASS: status is 200'));
      expect(ctx.errors, isEmpty);
    });

    test('runPostResponse detects failing assertion', () async {
      const script = "test('status is 400', response!['statusCode'] == 400);";

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {},
      );

      expect(ctx.assertions, contains('FAIL: status is 400'));
      expect(ctx.errors, isEmpty);
    });

    test('runPostResponse reads response body', () async {
      const script =
          "test('body has Alice', (response!['body'] as String).contains('Alice'));";

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {},
      );

      expect(ctx.assertions, contains('PASS: body has Alice'));
      expect(ctx.errors, isEmpty);
    });

    test('runPostResponse modifies variables and reads response', () async {
      const script = '''
variables['status'] = response!['statusCode'].toString();
test('got response', response!['body'] != '');
''';

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {'existing': 'val'},
      );

      expect(ctx.variables['existing'], 'val');
      expect(ctx.variables['status'], '200');
      expect(ctx.assertions, contains('PASS: got response'));
      expect(ctx.errors, isEmpty);
    });

    test('runPostResponse handles empty body', () async {
      final emptyResponse = models.HttpResponse(
        statusCode: 204,
        statusText: 'No Content',
        headers: {},
        bodyBytes: Uint8List(0),
        durationMs: 10,
        receivedAt: DateTime.now(),
      );

      const script = "test('status is 204', response!['statusCode'] == 204);";

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        emptyResponse,
        {},
      );

      expect(ctx.assertions, contains('PASS: status is 204'));
      expect(ctx.errors, isEmpty);
    });

    test('runPostResponse captures script errors', () async {
      const script = "throw FormatException('bad');";

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {},
      );

      expect(ctx.errors, isNotEmpty);
    });

    test('multiple assertions accumulate', () async {
      const script = '''
test('first', 1 == 1);
test('second', 2 == 3);
''';

      final ctx = await service.runPostResponse(
        script,
        sampleRequest,
        sampleResponse,
        {},
      );

      expect(ctx.assertions, contains('PASS: first'));
      expect(ctx.assertions, contains('FAIL: second'));
      expect(ctx.errors, isEmpty);
    });

    test('pre-request with special characters in variables', () async {
      final ctx = await service.runPreRequest(
        r"variables['dollar'] = '\$100';",
        sampleRequest,
        {},
      );

      expect(ctx.variables['dollar'], r'$100');
      expect(ctx.errors, isEmpty);
    });

    test('pre-request with single quotes in value', () async {
      final ctx = await service.runPreRequest(
        r"variables['q'] = 'it\'s ok';",
        sampleRequest,
        {},
      );

      expect(ctx.variables['q'], "it's ok");
      expect(ctx.errors, isEmpty);
    });
  });
}
