import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/repositories/workspace_repository.dart';
import 'package:http_client/services/cookie_jar.dart';

void main() {
  late Directory tempDir;
  late WorkspaceRepository repo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('http_client_test_');
    repo = WorkspaceRepository();
    await repo.open(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('WorkspaceRepository', () {
    // ---- No workspace ----
    test('hasWorkspace returns true after open', () {
      expect(repo.hasWorkspace, true);
    });

    test('loadCollections returns empty list when no collections', () async {
      final collections = await repo.loadCollections();
      expect(collections, isEmpty);
    });

    test('loadEnvironments returns empty list when no environments', () async {
      final envs = await repo.loadEnvironments();
      expect(envs, isEmpty);
    });

    test('loadHistory returns empty list when no history', () async {
      final history = await repo.loadHistory();
      expect(history, isEmpty);
    });

    test('loadCookies returns empty CookieJar when no cookies file', () async {
      final jar = await repo.loadCookies();
      expect(jar.cookies, isEmpty);
    });

    test('loadSettings returns empty map when no settings file', () async {
      final settings = await repo.loadSettings();
      expect(settings, isEmpty);
    });

    // ---- Collections ----
    test('saves and loads a collection', () async {
      final collection = RequestCollection(
        id: 'col-1',
        name: 'My API',
        description: 'Test collection',
      );

      await repo.saveCollection(collection);
      final collections = await repo.loadCollections();

      expect(collections.length, 1);
      expect(collections[0].id, 'col-1');
      expect(collections[0].name, 'My API');
      expect(collections[0].description, 'Test collection');
      expect(collections[0].folders, isEmpty);
    });

    test('saves multiple collections and loads all', () async {
      await repo.saveCollection(
        RequestCollection(id: 'col-1', name: 'Collection A'),
      );
      await repo.saveCollection(
        RequestCollection(id: 'col-2', name: 'Collection B'),
      );

      final collections = await repo.loadCollections();
      expect(collections.length, 2);
      expect(collections.map((c) => c.id), containsAll(['col-1', 'col-2']));
    });

    test('deletes a collection', () async {
      await repo.saveCollection(
        RequestCollection(id: 'col-1', name: 'To Delete'),
      );
      await repo.deleteCollection('col-1');

      final collections = await repo.loadCollections();
      expect(collections, isEmpty);
    });

    test('deleteCollection handles non-existent id gracefully', () async {
      await repo.saveCollection(RequestCollection(id: 'col-1', name: 'Keep'));
      // Should not throw.
      await repo.deleteCollection('non-existent');
      final collections = await repo.loadCollections();
      expect(collections.length, 1);
    });

    // ---- Folders ----
    test('saves and retrieves folders in a collection', () async {
      await repo.saveCollection(RequestCollection(id: 'col-1', name: 'API'));
      final folder = RequestFolder(id: 'f-1', name: 'Auth');

      await repo.saveFolder('col-1', folder);
      final collections = await repo.loadCollections();

      expect(collections[0].folders.length, 1);
      expect(collections[0].folders[0].id, 'f-1');
      expect(collections[0].folders[0].name, 'Auth');
    });

    test('deletes a folder from a collection', () async {
      await repo.saveCollection(RequestCollection(id: 'col-1', name: 'API'));
      await repo.saveFolder('col-1', RequestFolder(id: 'f-1', name: 'Auth'));
      await repo.saveFolder('col-1', RequestFolder(id: 'f-2', name: 'Users'));

      await repo.deleteFolder('col-1', 'f-1');
      final collections = await repo.loadCollections();

      expect(collections[0].folders.length, 1);
      expect(collections[0].folders[0].id, 'f-2');
    });

    // ---- Requests ----
    test('saves and loads requests for a collection', () async {
      final collection = RequestCollection(id: 'col-1', name: 'API');
      await repo.saveCollection(collection);

      final request = HttpRequest(
        id: 'req-1',
        name: 'Get Users',
        method: HttpMethod.get,
        url: 'https://api.example.com/users',
      );
      await repo.saveRequest(request, 'col-1');

      final requests = await repo.loadAllRequests('col-1');
      expect(requests.length, 1);
      expect(requests[0].id, 'req-1');
      expect(requests[0].name, 'Get Users');
      expect(requests[0].url, 'https://api.example.com/users');
      expect(requests[0].method, HttpMethod.get);
    });

    test('saves request in a folder', () async {
      final collection = RequestCollection(id: 'col-1', name: 'API');
      await repo.saveCollection(collection);

      await repo.saveFolder('col-1', RequestFolder(id: 'f-1', name: 'Users'));

      final request = HttpRequest(
        id: 'req-1',
        name: 'Get Users',
        method: HttpMethod.get,
        url: 'https://api.example.com/users',
        parentFolderId: 'f-1',
      );
      await repo.saveRequest(request, 'col-1');

      final folderRequests = await repo.loadRequestsForCollection(
        'col-1',
        folderId: 'f-1',
      );
      expect(folderRequests.length, 1);
      expect(folderRequests[0].name, 'Get Users');
    });

    test('deletes a request', () async {
      final collection = RequestCollection(id: 'col-1', name: 'API');
      await repo.saveCollection(collection);

      final request = HttpRequest(
        id: 'req-1',
        name: 'Get Users',
        method: HttpMethod.get,
        url: 'https://api.example.com/users',
      );
      await repo.saveRequest(request, 'col-1');
      await repo.deleteRequest(request, 'col-1');

      final requests = await repo.loadAllRequests('col-1');
      expect(requests, isEmpty);
    });

    // ---- Environments ----
    test('saves and loads an environment', () async {
      final env = Environment(
        id: 'env-1',
        name: 'Production',
        variables: [
          EnvironmentVariable(
            key: 'base_url',
            value: 'https://prod.example.com',
          ),
        ],
      );

      await repo.saveEnvironment(env);
      final envs = await repo.loadEnvironments();

      expect(envs.length, 1);
      expect(envs[0].id, 'env-1');
      expect(envs[0].name, 'Production');
      expect(envs[0].variables.length, 1);
      expect(envs[0].variables[0].key, 'base_url');
      expect(envs[0].variables[0].value, 'https://prod.example.com');
    });

    test('deletes an environment', () async {
      final env = Environment(id: 'env-1', name: 'Staging');
      await repo.saveEnvironment(env);
      await repo.deleteEnvironment('env-1');

      final envs = await repo.loadEnvironments();
      expect(envs, isEmpty);
    });

    // ---- History ----
    test('saves and loads history in reverse chronological order', () async {
      final entry1 = HistoryEntry(
        id: 'h-1',
        timestamp: DateTime(2026, 6, 26, 10, 0, 0),
        request: HttpRequest(
          id: 'req-1',
          name: 'Test',
          method: HttpMethod.get,
          url: 'https://example.com',
        ),
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        responseSizeBytes: 50,
      );
      final entry2 = HistoryEntry(
        id: 'h-2',
        timestamp: DateTime(2026, 6, 27, 10, 0, 0),
        request: HttpRequest(
          id: 'req-2',
          name: 'Test 2',
          method: HttpMethod.post,
          url: 'https://example.com/data',
        ),
        statusCode: 201,
        statusText: 'Created',
        durationMs: 200,
        responseSizeBytes: 100,
      );

      await repo.saveHistoryEntry(entry1);
      await repo.saveHistoryEntry(entry2);

      final history = await repo.loadHistory();
      expect(history.length, 2);
      // Most recent first.
      expect(history[0].id, 'h-2');
      expect(history[1].id, 'h-1');
    });

    test('deletes a history entry', () async {
      final entry = HistoryEntry(
        id: 'h-1',
        timestamp: DateTime.now(),
        request: HttpRequest(
          id: 'req-1',
          name: 'Test',
          method: HttpMethod.get,
          url: 'https://example.com',
        ),
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        responseSizeBytes: 50,
      );

      await repo.saveHistoryEntry(entry);
      await repo.deleteHistoryEntry('h-1');
      final history = await repo.loadHistory();
      expect(history, isEmpty);
    });

    test('clears all history', () async {
      await repo.saveHistoryEntry(
        HistoryEntry(
          id: 'h-1',
          timestamp: DateTime.now(),
          request: HttpRequest(
            id: 'req-1',
            name: 'Test',
            method: HttpMethod.get,
            url: 'https://example.com',
          ),
          statusCode: 200,
          statusText: 'OK',
          durationMs: 100,
          responseSizeBytes: 50,
        ),
      );
      await repo.clearHistory();
      final history = await repo.loadHistory();
      expect(history, isEmpty);
    });

    // ---- Cookies ----
    test('saves and loads cookies', () async {
      final jar = CookieJar(
        cookies: [
          StoredCookie(name: 'session', value: 'abc123', domain: 'example.com'),
        ],
      );

      await repo.saveCookies(jar);
      final loaded = await repo.loadCookies();

      expect(loaded.cookies.length, 1);
      expect(loaded.cookies[0].name, 'session');
      expect(loaded.cookies[0].value, 'abc123');
    });

    // ---- Settings ----
    test('saves and loads settings', () async {
      await repo.saveSettings({'theme': 'dark', 'timeout': 30});
      final settings = await repo.loadSettings();

      expect(settings['theme'], 'dark');
      expect(settings['timeout'], 30);
    });

    // ---- Roundtrip with full request ----
    test('saves and loads a complex request with full fidelity', () async {
      final collection = RequestCollection(id: 'col-1', name: 'API');
      await repo.saveCollection(collection);

      final request = HttpRequest(
        id: 'req-complex',
        name: 'Create User',
        method: HttpMethod.post,
        url: 'https://api.example.com/users',
        headers: [const KeyValuePair(key: 'X-Custom', value: 'val')],
        queryParams: [const KeyValuePair(key: 'debug', value: 'true')],
        body: const RequestBody(
          mode: BodyMode.raw,
          rawContent: '{"name":"Alice"}',
          rawContentType: RawContentType.json,
        ),
        auth: BearerAuth(token: 'tok-secret'),
        scripts: const RequestScripts(
          preRequest: "variables['x'] = '1';",
          postResponse: 'assert(response.statusCode == 200);',
        ),
      );

      await repo.saveRequest(request, 'col-1');
      final loaded = await repo.loadAllRequests('col-1');

      expect(loaded.length, 1);
      expect(loaded[0].id, 'req-complex');
      expect(loaded[0].name, 'Create User');
      expect(loaded[0].method, HttpMethod.post);
      expect(loaded[0].url, 'https://api.example.com/users');
      expect(loaded[0].headers.length, 1);
      expect(loaded[0].headers[0].key, 'X-Custom');
      expect(loaded[0].body.mode, BodyMode.raw);
      expect(loaded[0].body.rawContent, '{"name":"Alice"}');
      expect(loaded[0].body.rawContentType, RawContentType.json);
      expect(loaded[0].auth, isA<BearerAuth>());
      expect((loaded[0].auth as BearerAuth).token, 'tok-secret');
      expect(loaded[0].scripts.preRequest, "variables['x'] = '1';");
      expect(
        loaded[0].scripts.postResponse,
        'assert(response.statusCode == 200);',
      );
    });
  });
}
