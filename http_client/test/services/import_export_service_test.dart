import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/services/import_export_service.dart';

void main() {
  // -----------------------------------------------------------------------
  // CurlParser
  // -----------------------------------------------------------------------
  group('CurlParser', () {
    test('parses a GET request', () {
      final req = CurlParser.parse('curl https://api.example.com/users');
      expect(req.method, HttpMethod.get);
      expect(req.url, 'https://api.example.com/users');
      expect(req.headers, isEmpty);
      expect(req.body.mode, BodyMode.none);
    });

    test('parses a POST with JSON body and Content-Type header', () {
      final req = CurlParser.parse(
        '''curl -X POST https://api.example.com/data -H "Content-Type: application/json" -d '{"key":"value"}' ''',
      );

      expect(req.method, HttpMethod.post);
      expect(req.url, 'https://api.example.com/data');
      expect(req.headers.length, 1);
      expect(req.headers[0].key, 'Content-Type');
      expect(req.headers[0].value, 'application/json');
      expect(req.body.mode, BodyMode.raw);
      expect(req.body.rawContentType, RawContentType.json);
      expect(req.body.rawContent, '{"key":"value"}');
    });

    test('parses a POST with JSON body (auto-detect)', () {
      final req = CurlParser.parse(
        '''curl -X POST https://api.example.com/data -d '{"name":"test"}' ''',
      );

      expect(req.method, HttpMethod.post);
      expect(req.body.mode, BodyMode.raw);
      expect(req.body.rawContentType, RawContentType.json);
      expect(req.body.rawContent, '{"name":"test"}');
    });

    test('parses Basic auth with -u flag', () {
      final req = CurlParser.parse(
        "curl -u alice:secret https://api.example.com/secure",
      );

      expect(req.method, HttpMethod.get);
      expect(req.url, 'https://api.example.com/secure');
      expect(req.auth, isA<BasicAuth>());
      final basic = req.auth as BasicAuth;
      expect(basic.username, 'alice');
      expect(basic.password, 'secret');
    });

    test('parses Bearer auth from Authorization header', () {
      final req = CurlParser.parse(
        "curl -H 'Authorization: Bearer mytoken123' https://api.example.com/protected",
      );

      expect(req.auth, isA<BearerAuth>());
      final bearer = req.auth as BearerAuth;
      expect(bearer.token, 'mytoken123');
    });

    test('defaults to POST when -d is present without -X', () {
      final req = CurlParser.parse(
        "curl https://api.example.com/login -d 'user=admin&pass=123'",
      );

      expect(req.method, HttpMethod.post);
      expect(req.body.mode, BodyMode.urlEncoded);
      expect(req.body.formData.length, 2);
      expect(req.body.formData[0].key, 'user');
      expect(req.body.formData[0].value, 'admin');
      expect(req.body.formData[1].key, 'pass');
      expect(req.body.formData[1].value, '123');
    });

    test('parses a curl with multiple -d flags joined with &', () {
      final req = CurlParser.parse(
        "curl -d 'name=John' -d 'age=30' https://api.example.com/form",
      );

      expect(req.method, HttpMethod.post);
      expect(req.body.mode, BodyMode.urlEncoded);
      expect(req.body.formData.length, 2);
      expect(req.body.formData[0].key, 'name');
      expect(req.body.formData[0].value, 'John');
      expect(req.body.formData[1].key, 'age');
      expect(req.body.formData[1].value, '30');
    });

    test('parses Cookie header with -b flag', () {
      final req = CurlParser.parse(
        "curl -b 'session=abc123' https://api.example.com/dashboard",
      );

      expect(req.headers.any((h) => h.key == 'Cookie'), isTrue);
      expect(
        req.headers.firstWhere((h) => h.key == 'Cookie').value,
        'session=abc123',
      );
    });

    test('parses --data-urlencode flag', () {
      final req = CurlParser.parse(
        "curl --data-urlencode 'name=John Doe' https://api.example.com/submit",
      );

      expect(req.method, HttpMethod.post);
      expect(req.body.mode, BodyMode.urlEncoded);
      expect(req.body.formData.length, 1);
      expect(req.body.formData[0].key, 'name');
      expect(req.body.formData[0].value, 'John Doe');
    });

    test('parses -F form data', () {
      final req = CurlParser.parse(
        "curl -F 'field1=value1' -F 'field2=value2' https://api.example.com/upload",
      );

      expect(req.method, HttpMethod.post);
      expect(req.body.mode, BodyMode.formData);
      expect(req.body.formData.length, 2);
      expect(req.body.formData[0].key, 'field1');
      expect(req.body.formData[1].key, 'field2');
    });

    test('extracts query parameters from URL', () {
      final req = CurlParser.parse(
        'curl "https://api.example.com/search?q=dart&page=1"',
      );

      expect(req.url, 'https://api.example.com/search');
      expect(req.queryParams.length, 2);
      expect(req.queryParams[0].key, 'q');
      expect(req.queryParams[0].value, 'dart');
      expect(req.queryParams[1].key, 'page');
      expect(req.queryParams[1].value, '1');
    });

    test('uses --url flag', () {
      final req = CurlParser.parse('curl --url https://api.example.com/flag');

      expect(req.url, 'https://api.example.com/flag');
    });

    test('throws on empty command', () {
      expect(() => CurlParser.parse(''), throwsArgumentError);
    });

    test('throws on command without URL', () {
      expect(() => CurlParser.parse('curl -X GET'), throwsArgumentError);
    });
  });

  // -----------------------------------------------------------------------
  // OpenApiImporter
  // -----------------------------------------------------------------------
  group('OpenApiImporter', () {
    test('imports a minimal OpenAPI JSON with two paths', () {
      final json = '''
      {
        "openapi": "3.0.0",
        "info": {
          "title": "Pet Store",
          "version": "1.0.0"
        },
        "servers": [
          {"url": "https://api.petstore.com/v1"}
        ],
        "paths": {
          "/pets": {
            "get": {
              "operationId": "listPets",
              "summary": "List all pets"
            },
            "post": {
              "operationId": "createPet",
              "summary": "Create a pet"
            }
          },
          "/pets/{petId}": {
            "get": {
              "operationId": "getPet",
              "summary": "Get a pet by ID"
            }
          }
        }
      }
      ''';

      final result = OpenApiImporter.import(json, isYaml: false);

      expect(result.collection.name, 'Pet Store');
      expect(result.requests.length, 3);

      expect(result.requests[0].name, 'listPets');
      expect(result.requests[0].method, HttpMethod.get);
      expect(result.requests[0].url, 'https://api.petstore.com/v1/pets');

      expect(result.requests[1].name, 'createPet');
      expect(result.requests[1].method, HttpMethod.post);
      expect(result.requests[1].url, 'https://api.petstore.com/v1/pets');

      expect(result.requests[2].name, 'getPet');
      expect(result.requests[2].method, HttpMethod.get);
      expect(
        result.requests[2].url,
        'https://api.petstore.com/v1/pets/{petId}',
      );
    });

    test('imports YAML OpenAPI', () {
      final yaml = '''
openapi: "3.0.0"
info:
  title: Minimal API
  version: "1.0"
servers:
  - url: https://api.example.com
paths:
  /status:
    get:
      operationId: getStatus
  /items:
    post:
      operationId: createItem
''';

      final result = OpenApiImporter.import(yaml, isYaml: true);

      expect(result.collection.name, 'Minimal API');
      expect(result.requests.length, 2);
      expect(result.requests[0].name, 'getStatus');
      expect(result.requests[1].name, 'createItem');
    });

    test('imports OpenAPI with query parameters', () {
      final json = '''
      {
        "openapi": "3.0.0",
        "info": {"title": "Search API", "version": "1.0.0"},
        "servers": [{"url": "https://api.example.com"}],
        "paths": {
          "/search": {
            "get": {
              "operationId": "search",
              "parameters": [
                {"name": "q", "in": "query", "schema": {"type": "string"}},
                {"name": "limit", "in": "query", "schema": {"type": "integer"}}
              ]
            }
          }
        }
      }
      ''';

      final result = OpenApiImporter.import(json, isYaml: false);

      expect(result.requests.length, 1);
      final req = result.requests.first;
      expect(req.queryParams.length, 2);
      expect(req.queryParams[0].key, 'q');
      expect(req.queryParams[1].key, 'limit');
    });

    test('imports OpenAPI with header parameters', () {
      final json = '''
      {
        "openapi": "3.0.0",
        "info": {"title": "Auth API", "version": "1.0.0"},
        "servers": [{"url": "https://api.example.com"}],
        "paths": {
          "/admin": {
            "get": {
              "operationId": "admin",
              "parameters": [
                {"name": "X-API-Key", "in": "header", "schema": {"type": "string"}}
              ]
            }
          }
        }
      }
      ''';

      final result = OpenApiImporter.import(json, isYaml: false);

      expect(result.requests.length, 1);
      final req = result.requests.first;
      expect(req.headers.length, 1);
      expect(req.headers[0].key, 'X-API-Key');
    });
  });

  // -----------------------------------------------------------------------
  // CurlExporter
  // -----------------------------------------------------------------------
  group('CurlExporter', () {
    test('exports a simple GET request', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Health',
          method: HttpMethod.get,
          url: 'https://api.example.com/health',
        ),
      ];

      final script = CurlExporter.export(requests);
      expect(script, contains('#!/bin/bash'));
      expect(script, contains('curl'));
      expect(script, contains('https://api.example.com/health'));
      // GET is the default, so no -X GET should appear
      expect(script, isNot(contains('-X GET')));
      expect(script, isNot(contains('-X GET')));
    });

    test('exports a POST request with JSON body and headers', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Create',
          method: HttpMethod.post,
          url: 'https://api.example.com/data',
          headers: [
            KeyValuePair(key: 'Content-Type', value: 'application/json'),
          ],
          body: RequestBody(
            mode: BodyMode.raw,
            rawContent: '{"key":"value"}',
            rawContentType: RawContentType.json,
          ),
        ),
      ];

      final script = CurlExporter.export(requests);
      expect(script, contains('-X POST'));
      expect(script, contains('https://api.example.com/data'));
      expect(script, contains('-H'));
      expect(script, contains('Content-Type: application/json'));
      expect(script, contains('-d'));
      expect(script, contains('{"key":"value"}'));
    });

    test('exports Basic auth', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Secure',
          method: HttpMethod.get,
          url: 'https://api.example.com/secure',
          auth: BasicAuth(username: 'alice', password: 'secret'),
        ),
      ];

      final script = CurlExporter.export(requests);
      expect(script, contains('-u'));
      expect(script, contains('alice:secret'));
    });

    test('exports Bearer auth as header', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Protected',
          method: HttpMethod.get,
          url: 'https://api.example.com/protected',
          auth: BearerAuth(token: 'tok123'),
        ),
      ];

      final script = CurlExporter.export(requests);
      expect(script, contains('Authorization: Bearer tok123'));
    });

    test('exports query parameters appended to URL', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Search',
          method: HttpMethod.get,
          url: 'https://api.example.com/search',
          queryParams: [
            KeyValuePair(key: 'q', value: 'flutter'),
            KeyValuePair(key: 'page', value: '1'),
          ],
        ),
      ];

      final script = CurlExporter.export(requests);
      expect(script, contains('q=flutter'));
      expect(script, contains('page=1'));
    });

    test('exports multiple requests', () {
      final requests = [
        HttpRequest(
          id: '1',
          name: 'Health',
          method: HttpMethod.get,
          url: 'https://api.example.com/health',
        ),
        HttpRequest(
          id: '2',
          name: 'Status',
          method: HttpMethod.get,
          url: 'https://api.example.com/status',
        ),
      ];

      final script = CurlExporter.export(requests);
      // Should contain two curl commands
      expect(script.split('\n').where((l) => l.startsWith('curl')).length, 2);
    });
  });

  // -----------------------------------------------------------------------
  // OpenApiExporter
  // -----------------------------------------------------------------------
  group('OpenApiExporter', () {
    test('exports a collection to OpenAPI JSON', () {
      final collection = RequestCollection(
        id: 'c1',
        name: 'My API',
        description: 'A sample API',
      );

      final requests = [
        HttpRequest(
          id: '1',
          name: 'listUsers',
          method: HttpMethod.get,
          url: 'https://api.example.com/users',
        ),
        HttpRequest(
          id: '2',
          name: 'createUser',
          method: HttpMethod.post,
          url: 'https://api.example.com/users',
          headers: [
            KeyValuePair(key: 'Content-Type', value: 'application/json'),
          ],
          body: RequestBody(
            mode: BodyMode.raw,
            rawContent: '{"name":"test"}',
            rawContentType: RawContentType.json,
          ),
        ),
      ];

      final output = OpenApiExporter.export(collection, requests);

      // Verify basic structure
      expect(output, contains('"openapi": "3.0.0"'));
      expect(output, contains('"title": "My API"'));
      expect(output, contains('"description": "A sample API"'));
      expect(output, contains('"url": "https://api.example.com"'));

      // Verify paths
      expect(output, contains('"/users"'));

      // Verify operations
      expect(output, contains('listUsers'));
      expect(output, contains('createUser'));

      // Verify requestBody
      expect(output, contains('"requestBody"'));
      expect(output, contains('"application/json"'));
      expect(output, contains(r'{\"name\":\"test\"}'));

      // Verify placeholder responses
      expect(output, contains('"responses"'));
      expect(output, contains('"Successful response"'));

      // Valid JSON
      expect(() => jsonDecode(output), returnsNormally);
    });

    test('exports empty collection', () {
      final collection = RequestCollection(id: 'c1', name: 'Empty');
      final output = OpenApiExporter.export(collection, []);

      final decoded = jsonDecode(output) as Map<String, dynamic>;
      expect(decoded['paths'], <String, dynamic>{});
      expect(decoded['servers'], [
        {'url': 'http://localhost'},
      ]);
    });

    test('exports query parameters as OpenAPI parameters', () {
      final collection = RequestCollection(id: 'c1', name: 'Search API');
      final requests = [
        HttpRequest(
          id: '1',
          name: 'search',
          method: HttpMethod.get,
          url: 'https://api.example.com/search',
          queryParams: [KeyValuePair(key: 'q', value: 'flutter')],
        ),
      ];

      final output = OpenApiExporter.export(collection, requests);
      expect(output, contains('"in": "query"'));
      expect(output, contains('"q"'));
      expect(output, contains('"flutter"'));
    });
  });
}
