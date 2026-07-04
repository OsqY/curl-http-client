import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/repositories/workspace_repository.dart';
import 'package:http_client/services/auth_service.dart';
import 'package:http_client/services/cookie_jar.dart';
import 'package:http_client/services/http_service.dart';
import 'package:http_client/services/import_export_service.dart';
import 'package:http_client/services/scripting_service.dart';

final workspaceRepositoryProvider = Provider((ref) => WorkspaceRepository());

final authServiceProvider = Provider((ref) => AuthService());

final httpServiceProvider = Provider((ref) {
  final cookieJar = ref.watch(cookieJarProvider);
  return HttpService(cookieJar: cookieJar);
});

final scriptingServiceProvider = Provider((ref) => ScriptingService());

final importExportServiceProvider = Provider((ref) => ImportExportService());

final cookieJarProvider = StateNotifierProvider<CookieJarNotifier, CookieJar>(
  (ref) => CookieJarNotifier(ref.read(workspaceRepositoryProvider)),
);

class CookieJarNotifier extends StateNotifier<CookieJar> {
  final WorkspaceRepository _repo;

  CookieJarNotifier(this._repo) : super(CookieJar());

  Future<void> load() async {
    state = await _repo.loadCookies();
  }

  Future<void> clearCookies() async {
    state = CookieJar();
    await _repo.saveCookies(state);
  }

  Future<void> persist() async {
    await _repo.saveCookies(state);
  }
}

final collectionsProvider =
    StateNotifierProvider<
      CollectionsNotifier,
      AsyncValue<List<RequestCollection>>
    >((ref) => CollectionsNotifier(ref.read(workspaceRepositoryProvider)));

class CollectionsNotifier
    extends StateNotifier<AsyncValue<List<RequestCollection>>> {
  final WorkspaceRepository _repo;

  CollectionsNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = await AsyncValue.guard(_repo.loadCollections);
  }

  Future<void> save(RequestCollection collection) async {
    await _repo.saveCollection(collection);
    await load();
  }

  Future<void> delete(String collectionId) async {
    await _repo.deleteCollection(collectionId);
    await load();
  }
}

final environmentsProvider =
    StateNotifierProvider<EnvironmentsNotifier, AsyncValue<List<Environment>>>(
      (ref) => EnvironmentsNotifier(ref.read(workspaceRepositoryProvider)),
    );

class EnvironmentsNotifier
    extends StateNotifier<AsyncValue<List<Environment>>> {
  final WorkspaceRepository _repo;

  EnvironmentsNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = await AsyncValue.guard(_repo.loadEnvironments);
  }

  Future<void> save(Environment env) async {
    await _repo.saveEnvironment(env);
    await load();
  }

  Future<void> delete(String envId) async {
    await _repo.deleteEnvironment(envId);
    await load();
  }
}

final activeEnvironmentProvider = StateProvider<Environment?>((ref) => null);

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<HistoryEntry>>>(
      (ref) => HistoryNotifier(ref.read(workspaceRepositoryProvider)),
    );

class HistoryNotifier extends StateNotifier<AsyncValue<List<HistoryEntry>>> {
  final WorkspaceRepository _repo;

  HistoryNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = await AsyncValue.guard(_repo.loadHistory);
  }

  Future<void> add(HistoryEntry entry) async {
    await _repo.saveHistoryEntry(entry);
    await load();
  }

  Future<void> clear() async {
    await _repo.clearHistory();
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteHistoryEntry(id);
    await load();
  }
}

final currentRequestProvider = StateProvider<HttpRequest>(
  (ref) => HttpRequest(
    id: HttpRequest.generateId(),
    name: 'Untitled',
    method: HttpMethod.get,
    url: 'https://httpbin.org/get',
  ),
);

final responseProvider = StateProvider<HttpResponse?>((ref) => null);
final executionErrorProvider = StateProvider<String?>((ref) => null);
final isSendingProvider = StateProvider<bool>((ref) => false);
final scriptOutputProvider = StateProvider<String?>((ref) => null);
final workspacePathProvider = StateProvider<String?>((ref) => null);

final activeEnvironmentVariablesProvider = Provider<Map<String, String>>((ref) {
  final env = ref.watch(activeEnvironmentProvider);
  if (env == null) return {};
  return {
    for (final v in env.variables)
      if (v.enabled) v.key: v.value,
  };
});

/// Tracks whether the current request has unsaved changes.
final unsavedChangesProvider = StateProvider<bool>((ref) => false);

/// Available Soot theme variants.
enum SootThemeVariant { dark, light, orange }

/// Current active theme variant.
final themeVariantProvider = StateProvider<SootThemeVariant>(
  (ref) => SootThemeVariant.dark,
);
