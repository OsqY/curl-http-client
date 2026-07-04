import 'dart:convert';
import 'dart:io';

import 'package:http_client/models/models.dart';
import 'package:http_client/services/cookie_jar.dart';
import 'package:http_client/utils/utils.dart';
import 'package:path/path.dart' as path;

/// Manages the workspace directory and all persisted JSON files.
class WorkspaceRepository {
  Directory? _workspaceDir;

  Directory? get workspaceDir => _workspaceDir;

  bool get hasWorkspace => _workspaceDir != null && _workspaceDir!.existsSync();

  /// Opens a workspace directory, creating the required subdirectories.
  Future<void> open(String pathStr) async {
    final dir = Directory(pathStr);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _workspaceDir = dir;
    await _ensureStructure();
  }

  Future<void> _ensureStructure() async {
    final dirs = [collectionsDir, environmentsDir, historyDir];
    for (final dir in dirs) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  Directory get collectionsDir =>
      Directory(path.join(_workspaceDir!.path, 'collections'));
  Directory get environmentsDir =>
      Directory(path.join(_workspaceDir!.path, 'environments'));
  Directory get historyDir =>
      Directory(path.join(_workspaceDir!.path, 'history'));
  File get cookiesFile => File(path.join(_workspaceDir!.path, 'cookies.json'));
  File get settingsFile =>
      File(path.join(_workspaceDir!.path, 'settings.json'));

  // === Collections ===

  Future<List<RequestCollection>> loadCollections() async {
    if (!hasWorkspace) return [];
    final collections = <RequestCollection>[];
    await for (final entity in collectionsDir.list()) {
      if (entity is Directory) {
        final metaFile = File(path.join(entity.path, 'collection.json'));
        if (await metaFile.exists()) {
          final json =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          collections.add(RequestCollection.fromJson(json));
        }
      }
    }
    return collections;
  }

  Future<void> saveCollection(RequestCollection collection) async {
    if (!hasWorkspace) return;
    final dir = Directory(
      path.join(collectionsDir.path, slugify(collection.name)),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    final metaFile = File(path.join(dir.path, 'collection.json'));
    await metaFile.writeAsString(_prettyJson(collection.toJson()));
  }

  Future<void> deleteCollection(String collectionId) async {
    final dir = await _collectionDirById(collectionId);
    if (dir != null) await dir.delete(recursive: true);
  }

  Future<Directory?> _collectionDirById(String id) async {
    await for (final entity in collectionsDir.list()) {
      if (entity is Directory) {
        final metaFile = File(path.join(entity.path, 'collection.json'));
        if (await metaFile.exists()) {
          final json =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          if (json['id'] == id) return entity;
        }
      }
    }
    return null;
  }

  // === Folders ===

  Future<void> saveFolder(String collectionId, RequestFolder folder) async {
    final collection = await _findCollection(collectionId);
    if (collection == null) return;
    final updated = collection.copyWith(
      folders: [...collection.folders.where((f) => f.id != folder.id), folder],
    );
    await saveCollection(updated);
  }

  Future<void> deleteFolder(String collectionId, String folderId) async {
    final collection = await _findCollection(collectionId);
    if (collection == null) return;
    final updated = collection.copyWith(
      folders: collection.folders.where((f) => f.id != folderId).toList(),
    );
    await saveCollection(updated);
  }

  Future<RequestCollection?> _findCollection(String id) async {
    final collections = await loadCollections();
    try {
      return collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // === Requests ===

  Future<List<HttpRequest>> loadRequestsForCollection(
    String collectionId, {
    String? folderId,
  }) async {
    if (!hasWorkspace) return [];
    final dir = await _collectionDirById(collectionId);
    if (dir == null) return [];
    final requests = <HttpRequest>[];
    final targetDir = folderId == null
        ? dir
        : Directory(path.join(dir.path, slugify(folderId)));
    if (!await targetDir.exists()) return [];
    await for (final entity in targetDir.list()) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          !entity.path.endsWith('collection.json')) {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        requests.add(HttpRequest.fromJson(json));
      }
    }
    return requests;
  }

  Future<List<HttpRequest>> loadAllRequests(String collectionId) async {
    final dir = await _collectionDirById(collectionId);
    if (dir == null) return [];
    return _loadRequestsRecursive(dir);
  }

  Future<List<HttpRequest>> _loadRequestsRecursive(Directory dir) async {
    final requests = <HttpRequest>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          !entity.path.endsWith('collection.json')) {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        requests.add(HttpRequest.fromJson(json));
      } else if (entity is Directory) {
        requests.addAll(await _loadRequestsRecursive(entity));
      }
    }
    return requests;
  }

  Future<void> saveRequest(HttpRequest request, String collectionId) async {
    if (!hasWorkspace) return;
    final dir = await _collectionDirById(collectionId);
    if (dir == null) return;
    final folderDir = request.parentFolderId != null
        ? Directory(path.join(dir.path, slugify(request.parentFolderId!)))
        : dir;
    if (!await folderDir.exists()) await folderDir.create(recursive: true);
    final file = File(
      path.join(folderDir.path, '${slugify(request.name)}.json'),
    );
    await file.writeAsString(_prettyJson(request.toJson()));
  }

  Future<void> deleteRequest(HttpRequest request, String collectionId) async {
    final dir = await _collectionDirById(collectionId);
    if (dir == null) return;
    final folderDir = request.parentFolderId != null
        ? Directory(path.join(dir.path, slugify(request.parentFolderId!)))
        : dir;
    final file = File(
      path.join(folderDir.path, '${slugify(request.name)}.json'),
    );
    if (await file.exists()) await file.delete();
  }

  // === Environments ===

  Future<List<Environment>> loadEnvironments() async {
    if (!hasWorkspace) return [];
    final environments = <Environment>[];
    await for (final entity in environmentsDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        environments.add(Environment.fromJson(json));
      }
    }
    return environments;
  }

  Future<void> saveEnvironment(Environment environment) async {
    if (!hasWorkspace) return;
    final file = File(
      path.join(environmentsDir.path, '${slugify(environment.name)}.json'),
    );
    await file.writeAsString(_prettyJson(environment.toJson()));
  }

  Future<void> deleteEnvironment(String environmentId) async {
    final envs = await loadEnvironments();
    Environment? env;
    try {
      env = envs.firstWhere((e) => e.id == environmentId);
    } catch (_) {
      env = null;
    }
    if (env != null) {
      final file = File(
        path.join(environmentsDir.path, '${slugify(env.name)}.json'),
      );
      if (await file.exists()) await file.delete();
    }
  }

  // === History ===

  Future<List<HistoryEntry>> loadHistory() async {
    if (!hasWorkspace) return [];
    final entries = <HistoryEntry>[];
    await for (final entity in historyDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        entries.add(HistoryEntry.fromJson(json));
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> saveHistoryEntry(HistoryEntry entry) async {
    if (!hasWorkspace) return;
    final file = File(path.join(historyDir.path, '${entry.id}.json'));
    await file.writeAsString(_prettyJson(entry.toJson()));
  }

  Future<void> deleteHistoryEntry(String id) async {
    final file = File(path.join(historyDir.path, '$id.json'));
    if (await file.exists()) await file.delete();
  }

  Future<void> clearHistory() async {
    if (!hasWorkspace) return;
    await for (final entity in historyDir.list()) {
      if (entity is File) await entity.delete();
    }
  }

  // === Cookies ===

  Future<CookieJar> loadCookies() async {
    if (!hasWorkspace || !await cookiesFile.exists()) return CookieJar();
    final json = jsonDecode(await cookiesFile.readAsString()) as List<dynamic>;
    return CookieJar.fromJson(json);
  }

  Future<void> saveCookies(CookieJar jar) async {
    if (!hasWorkspace) return;
    await cookiesFile.writeAsString(_prettyJson(jar.toJson()));
  }

  // === Settings ===

  Future<Map<String, dynamic>> loadSettings() async {
    if (!hasWorkspace || !await settingsFile.exists()) return {};
    return jsonDecode(await settingsFile.readAsString())
        as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (!hasWorkspace) return;
    await settingsFile.writeAsString(_prettyJson(settings));
  }

  String _prettyJson(dynamic json) =>
      const JsonEncoder.withIndent('  ').convert(json);
}
