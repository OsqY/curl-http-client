import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/method_badge.dart';
import 'package:http_client/utils/formatting.dart';
import 'package:http_client/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Clickable wrapper — shows hand cursor on desktop
// ---------------------------------------------------------------------------

class _ClickCursor extends StatelessWidget {
  final Widget child;
  const _ClickCursor({required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar row — replaces ListTile, no warnings
// ---------------------------------------------------------------------------

class _SidebarRow extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double leftPadding;

  const _SidebarRow({
    this.leading,
    this.title,
    this.trailing,
    this.onTap,
    this.onSecondaryTap,
    this.leftPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return _ClickCursor(
      child: GestureDetector(
        onSecondaryTapDown: onSecondaryTap != null
            ? (d) => onSecondaryTap!()
            : null,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.border.withAlpha(40),
          highlightColor: AppColors.border.withAlpha(60),
          child: Container(
            padding: EdgeInsets.only(
                left: leftPadding, right: 8, top: 4, bottom: 4),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.sidebarFg,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    child: title ?? const SizedBox.shrink(),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    final dir = await getApplicationDocumentsDirectory();
    final workspacePath = '${dir.path}/http_client_workspace';
    await _openWorkspace(workspacePath);
  }

  Future<void> _changeWorkspace() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select workspace directory',
    );
    if (path != null) {
      await _openWorkspace(path);
    }
  }

  Future<void> _openWorkspace(String workspacePath) async {
    await ref.read(workspaceRepositoryProvider).open(workspacePath);
    ref.read(workspacePathProvider.notifier).state = workspacePath;
    await ref.read(cookieJarProvider.notifier).load();
    await ref.read(collectionsProvider.notifier).load();
    await ref.read(environmentsProvider.notifier).load();
    await ref.read(historyProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final workspacePath = ref.watch(workspacePathProvider);

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _sendRequest,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _saveRequest,
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Sidebar
              SizedBox(
                width: 260,
                child: Container(
                  color: AppColors.sidebarBg,
                  child: _Sidebar(
                    onRequestSelected: (req) {
                      ref.read(currentRequestProvider.notifier).state = req;
                    },
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              // Center: request + response stacked
              Expanded(
                child: workspacePath == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _RequestEditor(
                              onSend: _sendRequest,
                              onSave: _saveRequest,
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          Expanded(
                            flex: 1,
                            child: _ResponsePanel(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Request actions ----

  Future<void> _sendRequest() async {
    final request = ref.read(currentRequestProvider);
    final variables = ref.read(activeEnvironmentVariablesProvider);

    ref.read(isSendingProvider.notifier).state = true;
    ref.read(responseProvider.notifier).state = null;
    ref.read(executionErrorProvider.notifier).state = null;
    ref.read(scriptOutputProvider.notifier).state = null;

    try {
      var effectiveVariables = Map<String, String>.from(variables);
      if (request.scripts.preRequest.isNotEmpty) {
        final scriptResult = await ref
            .read(scriptingServiceProvider)
            .runPreRequest(
                request.scripts.preRequest, request, effectiveVariables);
        effectiveVariables = Map<String, String>.from(scriptResult.variables);
        if (scriptResult.errors.isNotEmpty) {
          ref.read(scriptOutputProvider.notifier).state =
              'Pre-request script errors:\n${scriptResult.errors.join('\n')}';
        } else if (scriptResult.assertions.isNotEmpty) {
          ref.read(scriptOutputProvider.notifier).state =
              scriptResult.assertions.join('\n');
        }
      }

      String? accessToken;
      if (request.auth is OAuth2Auth) {
        accessToken = await ref
            .read(authServiceProvider)
            .getAccessToken(request.auth as OAuth2Auth);
      }

      final result = await ref
          .read(httpServiceProvider)
          .execute(request,
              variables: effectiveVariables, accessToken: accessToken);

      if (result.error != null) {
        ref.read(executionErrorProvider.notifier).state = result.error;
      } else if (result.response != null) {
        final response = result.response!;
        ref.read(responseProvider.notifier).state = response;

        if (request.scripts.postResponse.isNotEmpty) {
          final scriptResult =
              await ref.read(scriptingServiceProvider).runPostResponse(
                    request.scripts.postResponse,
                    request,
                    response,
                    effectiveVariables,
                  );
          final output = StringBuffer();
          if (scriptResult.errors.isNotEmpty) {
            output.writeln('Post-response script errors:');
            output.writeln(scriptResult.errors.join('\n'));
          }
          if (scriptResult.assertions.isNotEmpty) {
            output.writeln(scriptResult.assertions.join('\n'));
          }
          if (output.isNotEmpty) {
            ref.read(scriptOutputProvider.notifier).state = output.toString();
          }
        }

        final entry = HistoryEntry(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          request: request,
          statusCode: response.statusCode,
          statusText: response.statusText,
          durationMs: response.durationMs,
          responseSizeBytes: response.sizeBytes,
          responseBodyPreview: _previewBody(response),
        );
        await ref.read(historyProvider.notifier).add(entry);
        await ref.read(cookieJarProvider.notifier).persist();
      }
    } finally {
      ref.read(isSendingProvider.notifier).state = false;
    }
  }

  String? _previewBody(HttpResponse response) {
    final text = decodeBody(response.bodyBytes, response.headers);
    if (text == null) return null;
    if (text.length > 1000) return '${text.substring(0, 1000)}...';
    return text;
  }

  Future<void> _saveRequest() async {
    final request = ref.read(currentRequestProvider);
    final collections = ref.read(collectionsProvider).valueOrNull ?? [];
    if (collections.isEmpty) {
      final collection = RequestCollection(
        id: HttpRequest.generateId(),
        name: 'Default',
      );
      await ref.read(collectionsProvider.notifier).save(collection);
      await ref
          .read(workspaceRepositoryProvider)
          .saveRequest(request, collection.id);
    } else {
      await ref
          .read(workspaceRepositoryProvider)
          .saveRequest(request, collections.first.id);
    }
    await ref.read(collectionsProvider.notifier).load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request saved')),
      );
    }
    ref.read(unsavedChangesProvider.notifier).state = false;
  }

  // ---- Import/Export ----

  void _importCurl() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import curl'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Paste curl command'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      final request =
          ref.read(importExportServiceProvider).parseCurl(result);
      ref.read(currentRequestProvider.notifier).state = request;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _importOpenApi() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'yaml', 'yml'],
      withData: true,
    );
    if (file == null || file.files.isEmpty || file.files.first.bytes == null) {
      return;
    }
    try {
      final source = utf8.decode(file.files.first.bytes!);
      final isYaml =
          file.files.first.extension?.toLowerCase() != 'json';
      final importResult = ref
          .read(importExportServiceProvider)
          .importOpenApi(source, isYaml: isYaml);
      final collection = importResult.collection;
      await ref.read(collectionsProvider.notifier).save(collection);
      for (final req in importResult.requests) {
        await ref
            .read(workspaceRepositoryProvider)
            .saveRequest(req, collection.id);
      }
      await ref.read(collectionsProvider.notifier).load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Imported ${importResult.requests.length} requests')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OpenAPI import failed: $e')),
        );
      }
    }
  }

  void _exportCurl() async {
    final request = ref.read(currentRequestProvider);
    final script =
        ref.read(importExportServiceProvider).exportCurl([request]);
    final output = await FilePicker.platform.saveFile(
      dialogTitle: 'Save curl script',
      fileName: 'export.sh',
    );
    if (output != null) {
      await File(output).writeAsString(script);
    }
  }

  void _exportOpenApi() async {
    final collections = ref.read(collectionsProvider).valueOrNull ?? [];
    if (collections.isEmpty) return;
    final collection = collections.first;
    final requests = await ref
        .read(workspaceRepositoryProvider)
        .loadAllRequests(collection.id);
    final json = ref
        .read(importExportServiceProvider)
        .exportOpenApi(collection, requests);
    final output = await FilePicker.platform.saveFile(
      dialogTitle: 'Export OpenAPI',
      fileName: '${collection.name}.json',
    );
    if (output != null) {
      await File(output).writeAsString(json);
    }
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends ConsumerWidget {
  final void Function(HttpRequest) onRequestSelected;

  const _Sidebar({required this.onRequestSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final historyAsync = ref.watch(historyProvider);
    final envsAsync = ref.watch(environmentsProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Column(
      children: [
        // Workspace header
        Container(
          width: double.infinity,
          color: AppColors.sidebarHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Text(
            'HTTP Client',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // New request + menu
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: _ClickCursor(
                  child: InkWell(
                    onTap: () {
                      ref.read(currentRequestProvider.notifier).state =
                          HttpRequest(
                        id: HttpRequest.generateId(),
                        name: 'Untitled',
                        method: HttpMethod.get,
                        url: 'https://httpbin.org/get',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.paneHeaderBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              size: 14, color: AppColors.fgMuted),
                          SizedBox(width: 4),
                          Text('New Request',
                              style: TextStyle(
                                  color: AppColors.fgMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  final state =
                      context.findAncestorStateOfType<_MainScreenState>();
                  switch (v) {
                    case 'import_curl':
                      state?._importCurl();
                    case 'import_openapi':
                      state?._importOpenApi();
                    case 'export_curl':
                      state?._exportCurl();
                    case 'export_openapi':
                      state?._exportOpenApi();
                    case 'change_workspace':
                      state?._changeWorkspace();
                    case 'clear_cookies':
                      ref.read(cookieJarProvider.notifier).clearCookies();
                  }
                },
                icon: const Icon(Icons.more_vert,
                    size: 16, color: AppColors.fgMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'import_curl', child: Text('Import curl')),
                  const PopupMenuItem(
                      value: 'import_openapi', child: Text('Import OpenAPI')),
                  const PopupMenuItem(
                      value: 'export_curl', child: Text('Export curl')),
                  const PopupMenuItem(
                      value: 'export_openapi', child: Text('Export OpenAPI')),
                  const PopupMenuItem(
                      value: 'change_workspace',
                      child: Text('Change workspace')),
                  const PopupMenuItem(
                      value: 'clear_cookies', child: Text('Clear cookies')),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Environment selector + actions
        envsAsync.when(
          data: (envs) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                _ClickCursor(
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 14),
                    tooltip: 'New environment',
                    onPressed: () => _showEnvironmentDialog(context, ref),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<Environment?>(
                    initialValue: activeEnv,
                    key: ValueKey(activeEnv?.id),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<Environment?>(
                        value: null,
                        child: Text('No environment',
                            style: TextStyle(
                                color: AppColors.fgMuted, fontSize: 12)),
                      ),
                      ...envs.map((env) => DropdownMenuItem(
                            value: env,
                            child: Text(env.name,
                                style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                    onChanged: (v) => ref
                        .read(activeEnvironmentProvider.notifier)
                        .state = v,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                if (activeEnv != null) ...[
                  _ClickCursor(
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 14),
                      tooltip: 'Edit environment',
                      onPressed: () =>
                          _showEnvironmentDialog(context, ref, activeEnv),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        _confirmDeleteEnvironment(context, ref, activeEnv);
                      }
                    },
                    icon: const Icon(Icons.more_vert,
                        size: 14, color: AppColors.fgMuted),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete environment')),
                    ],
                  ),
                ],
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const Divider(height: 1),
        // Collections
        Expanded(
          child: collectionsAsync.when(
            data: (collections) => ListView(
              padding: EdgeInsets.zero,
              children: [
                // New collection button
                _SidebarRow(
                  leading:
                      const Icon(Icons.create_new_folder, size: 16),
                  title: const Text('New Collection',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.fgMuted)),
                  onTap: () => _showCollectionDialog(context, ref),
                ),
                ...collections.expand((collection) {
                  return [
                    // Collection header with hover actions
                    _CollectionHeader(
                      collection: collection,
                      onRename: () => _showCollectionDialog(
                          context, ref, collection),
                      onDelete: () =>
                          _confirmDeleteCollection(context, ref, collection),
                      onNewFolder: () =>
                          _showFolderDialog(context, ref, collection),
                    ),
                    // Folders
                    ...collection.folders.map((folder) => _SidebarRow(
                          leading:
                              const Icon(Icons.folder_open, size: 16),
                          title: Text(folder.name,
                              style: const TextStyle(fontSize: 12)),
                          leftPadding: 24,
                          onSecondaryTap: () =>
                              _showFolderContextMenu(context, ref, collection, folder),
                        )),
                    // Requests in collection
                    FutureBuilder<List<HttpRequest>>(
                      future: ref
                          .read(workspaceRepositoryProvider)
                          .loadAllRequests(collection.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return Column(
                          children: snapshot.data!
                              .map((req) => _SidebarRow(
                                    leading: MethodBadge(method: req.method),
                                    title: Text(req.name,
                                        style:
                                            const TextStyle(fontSize: 12)),
                                    leftPadding: 24,
                                    onTap: () => onRequestSelected(req),
                                    onSecondaryTap: () =>
                                        _showRequestContextMenu(
                                            context, ref, collection, req),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ];
                }),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        const Divider(height: 1),
        // History section
        _SectionHeader(title: 'History'),
        Expanded(
          child: historyAsync.when(
            data: (entries) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _SidebarRow(
                  leading: MethodBadge(method: entry.request.method),
                  title: Text(entry.request.url,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${entry.statusCode} • ${entry.durationMs}ms',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.fgMuted),
                  ),
                  onTap: () => onRequestSelected(entry.request),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ---- Dialogs ----

  Future<void> _showCollectionDialog(
    BuildContext context,
    WidgetRef ref, [
    RequestCollection? existing,
  ]) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New Collection' : 'Rename Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (existing != null) {
      await ref
          .read(collectionsProvider.notifier)
          .save(existing.copyWith(name: result));
    } else {
      await ref.read(collectionsProvider.notifier).save(
            RequestCollection(
              id: HttpRequest.generateId(),
              name: result,
            ),
          );
    }
  }

  Future<void> _confirmDeleteCollection(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection'),
        content: Text('Delete "${collection.name}" and all its requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(collectionsProvider.notifier)
          .delete(collection.id);
    }
  }

  Future<void> _showFolderDialog(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection, [
    RequestFolder? existing,
  ]) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New Folder' : 'Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final folders = List<RequestFolder>.from(collection.folders);
    if (existing != null) {
      final idx = folders.indexWhere((f) => f.id == existing.id);
      if (idx >= 0) folders[idx] = existing.copyWith(name: result);
    } else {
      folders.add(RequestFolder(
        id: HttpRequest.generateId(),
        name: result,
      ));
    }
    await ref
        .read(collectionsProvider.notifier)
        .save(collection.copyWith(folders: folders));
  }

  void _showFolderContextMenu(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
    RequestFolder folder,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fill,
      items: const [
        PopupMenuItem(value: 'new_request', child: Text('New Request')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((v) {
      if (v == null || !context.mounted) return;
      switch (v) {
        case 'new_request':
          ref.read(currentRequestProvider.notifier).state = HttpRequest(
            id: HttpRequest.generateId(),
            name: 'Untitled',
            method: HttpMethod.get,
            url: 'https://httpbin.org/get',
          );
        case 'rename':
          _showFolderDialog(context, ref, collection, folder);
        case 'delete':
          _confirmDeleteFolder(context, ref, collection, folder);
      }
    });
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
    RequestFolder folder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder'),
        content: Text('Delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final folders = collection.folders
          .where((f) => f.id != folder.id)
          .toList();
      await ref
          .read(collectionsProvider.notifier)
          .save(collection.copyWith(folders: folders));
    }
  }

  void _showRequestContextMenu(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
    HttpRequest request,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fill,
      items: const [
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((v) {
      if (v == null || !context.mounted) return;
      switch (v) {
        case 'duplicate':
          _duplicateRequest(ref, collection, request);
        case 'rename':
          _showRequestRenameDialog(context, ref, collection, request);
        case 'delete':
          _confirmDeleteRequest(context, ref, collection, request);
      }
    });
  }

  Future<void> _duplicateRequest(
    WidgetRef ref,
    RequestCollection collection,
    HttpRequest request,
  ) async {
    final duplicate = request.copyWith(
      id: HttpRequest.generateId(),
      name: '${request.name} (copy)',
    );
    await ref
        .read(workspaceRepositoryProvider)
        .saveRequest(duplicate, collection.id);
    ref.read(currentRequestProvider.notifier).state = duplicate;
  }

  Future<void> _showRequestRenameDialog(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
    HttpRequest request,
  ) async {
    final controller = TextEditingController(text: request.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref
        .read(workspaceRepositoryProvider)
        .saveRequest(request.copyWith(name: result), collection.id);
  }

  Future<void> _confirmDeleteRequest(
    BuildContext context,
    WidgetRef ref,
    RequestCollection collection,
    HttpRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request'),
        content: Text('Delete "${request.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(workspaceRepositoryProvider)
          .deleteRequest(request, collection.id);
    }
  }

  // ---- Environment dialogs ----

  Future<void> _showEnvironmentDialog(
    BuildContext context,
    WidgetRef ref, [
    Environment? existing,
  ]) async {
    final nameController =
        TextEditingController(text: existing?.name ?? 'New Env');
    final vars = existing?.variables.toList() ??
        [const EnvironmentVariable(key: '', value: '')];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(existing == null ? 'New Environment' : 'Edit Environment'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vars.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration:
                                const InputDecoration(labelText: 'Key'),
                            onChanged: (v) =>
                                vars[index] = vars[index].copyWith(key: v),
                            controller:
                                TextEditingController(text: vars[index].key),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration:
                                const InputDecoration(labelText: 'Value'),
                            onChanged: (v) => vars[index] =
                                vars[index].copyWith(value: v),
                            controller: TextEditingController(
                                text: vars[index].value),
                            obscureText: vars[index].secret,
                          ),
                        ),
                        IconButton(
                          icon: Icon(vars[index].secret
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => vars[index] =
                              vars[index].copyWith(secret: !vars[index].secret),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final env = Environment(
                id: existing?.id ?? HttpRequest.generateId(),
                name: nameController.text,
                variables:
                    vars.where((v) => v.key.isNotEmpty).toList(),
              );
              ref.read(environmentsProvider.notifier).save(env);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEnvironment(
    BuildContext context,
    WidgetRef ref,
    Environment env,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete environment'),
        content: Text('Delete "${env.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(environmentsProvider.notifier).delete(env.id);
      if (ref.read(activeEnvironmentProvider)?.id == env.id) {
        ref.read(activeEnvironmentProvider.notifier).state = null;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Collection header with hover actions
// ---------------------------------------------------------------------------

class _CollectionHeader extends StatefulWidget {
  final RequestCollection collection;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onNewFolder;

  const _CollectionHeader({
    required this.collection,
    required this.onRename,
    required this.onDelete,
    required this.onNewFolder,
  });

  @override
  State<_CollectionHeader> createState() => _CollectionHeaderState();
}

class _CollectionHeaderState extends State<_CollectionHeader> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: AppColors.paneHeaderBg,
        child: Row(
          children: [
            const Icon(Icons.folder, size: 14, color: AppColors.fgMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.collection.name,
                style: const TextStyle(
                  color: AppColors.fgMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hovering) ...[
              _ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  tooltip: 'New folder',
                  onPressed: widget.onNewFolder,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              _ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 14),
                  tooltip: 'Rename',
                  onPressed: widget.onRename,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              _ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.delete, size: 14),
                  tooltip: 'Delete',
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.paneHeaderBg,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.fgMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request Editor
// ---------------------------------------------------------------------------

class _RequestEditor extends ConsumerStatefulWidget {
  final VoidCallback onSend;
  final VoidCallback onSave;

  const _RequestEditor({required this.onSend, required this.onSave});

  @override
  ConsumerState<_RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends ConsumerState<_RequestEditor> {
  late TextEditingController _urlController;
  late TextEditingController _nameController;
  late TextEditingController _bodyController;
  late TextEditingController _preScriptController;
  late TextEditingController _postScriptController;
  String? _lastRequestId;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _nameController = TextEditingController();
    _bodyController = TextEditingController();
    _preScriptController = TextEditingController();
    _postScriptController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _bodyController.dispose();
    _preScriptController.dispose();
    _postScriptController.dispose();
    super.dispose();
  }

  void _setControllerText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(currentRequestProvider);
    final hasUnsaved = ref.watch(unsavedChangesProvider);

    if (request.id != _lastRequestId) {
      _lastRequestId = request.id;
      ref.read(unsavedChangesProvider.notifier).state = false;
      _setControllerText(_urlController, request.url);
      _setControllerText(_nameController, request.name);
      _setControllerText(_bodyController, request.body.rawContent);
      _setControllerText(_preScriptController, request.scripts.preRequest);
      _setControllerText(_postScriptController, request.scripts.postResponse);
    }

    return Column(
      children: [
        // Title (above URL bar)
        Container(
          color: AppColors.paneHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: AppColors.fgDefault,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Request name',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    hintStyle: TextStyle(color: AppColors.fgMuted, fontSize: 13),
                  ),
                  onChanged: (v) {
                    ref.read(unsavedChangesProvider.notifier).state = true;
                    ref
                        .read(currentRequestProvider.notifier)
                        .state = request.copyWith(name: v);
                  },
                ),
              ),
              if (hasUnsaved)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: 'Unsaved changes',
                    child: Icon(Icons.circle, size: 6, color: AppColors.bgWarning),
                  ),
                ),
            ],
          ),
        ),
        // URL bar
        Container(
          color: AppColors.paneHeaderBg,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              // Method badge
              _ClickCursor(
                child: PopupMenuButton<HttpMethod>(
                  onSelected: (m) {
                    ref.read(unsavedChangesProvider.notifier).state = true;
                    ref.read(currentRequestProvider.notifier).state =
                        request.copyWith(method: m);
                  },
                  offset: const Offset(0, 30),
                  itemBuilder: (context) => HttpMethod.values
                      .map((m) => PopupMenuItem(
                            value: m,
                            child: Row(
                              children: [
                                MethodBadge(method: m),
                                const SizedBox(width: 8),
                                Text(m.name.toUpperCase()),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.paneBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MethodBadge(method: request.method),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 14, color: AppColors.fgMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // URL input
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter URL',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) {
                    ref.read(unsavedChangesProvider.notifier).state = true;
                    ref
                        .read(currentRequestProvider.notifier)
                        .state = request.copyWith(url: v);
                  },
                ),
              ),
              const SizedBox(width: 6),
              // Send button
              _ClickCursor(
                child: InkWell(
                  onTap: widget.onSend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgSuccess,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.save, size: 18),
                  tooltip: 'Save (Ctrl+S)',
                  onPressed: widget.onSave,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ),
            ],
          ),
        ),
        // Tabs
        Expanded(
          child: DefaultTabController(
            length: 6,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Params'),
                    Tab(text: 'Headers'),
                    Tab(text: 'Auth'),
                    Tab(text: 'Body'),
                    Tab(text: 'Scripts'),
                    Tab(text: 'Settings'),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: AppColors.paneBg,
                    child: TabBarView(
                      children: [
                        _KeyValueEditor(
                          items: request.queryParams,
                          onChanged: (v) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(queryParams: v);
                          },
                        ),
                        _KeyValueEditor(
                          items: request.headers,
                          onChanged: (v) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(headers: v);
                          },
                        ),
                        _AuthEditor(
                          auth: request.auth,
                          onChanged: (a) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(auth: a);
                          },
                        ),
                        _BodyEditor(
                          body: request.body,
                          onChanged: (b) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(body: b);
                          },
                        ),
                        _ScriptsEditor(
                          scripts: request.scripts,
                          onChanged: (s) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(scripts: s);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: Text('Settings coming soon',
                                style: TextStyle(
                                    color: AppColors.fgMuted, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Response Panel
// ---------------------------------------------------------------------------

class _ResponsePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final response = ref.watch(responseProvider);
    final error = ref.watch(executionErrorProvider);
    final isSending = ref.watch(isSendingProvider);
    final scriptOutput = ref.watch(scriptOutputProvider);

    if (isSending) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error,
            style: const TextStyle(color: AppColors.bgDanger, fontSize: 13)),
      );
    }

    if (response == null) {
      return const Center(
        child: Text('Send a request to see the response',
            style: TextStyle(color: AppColors.fgMuted, fontSize: 13)),
      );
    }

    final bodyText = response.bodyText ?? '<binary>';
    final contentType =
        response.headers['content-type']?.toLowerCase() ?? '';
    final language = _detectLanguage(contentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status bar
        Container(
          color: AppColors.paneHeaderBg,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              _StatusTag(statusCode: response.statusCode),
              const SizedBox(width: 12),
              Text('${response.durationMs} ms',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.paneHeaderFg)),
              const SizedBox(width: 12),
              Text(formatBytes(response.sizeBytes),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.paneHeaderFg)),
              const Spacer(),
              _ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.save, size: 16),
                  tooltip: 'Save response',
                  onPressed: () => _saveResponse(context, response),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ],
          ),
        ),
        if (scriptOutput != null)
          Container(
            width: double.infinity,
            color: AppColors.paneHeaderBg,
            padding: const EdgeInsets.all(8),
            child: Text(scriptOutput,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.fgMuted)),
          ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Body'), Tab(text: 'Headers')]),
                Expanded(
                  child: Container(
                    color: AppColors.paneBg,
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: HighlightView(
                            _prettyBody(bodyText, contentType),
                            language: language,
                            theme: vs2015Theme,
                            padding: const EdgeInsets.all(10),
                            textStyle: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                        ListView.builder(
                          itemCount: response.headers.length,
                          itemBuilder: (context, index) {
                            final entry =
                                response.headers.entries.elementAt(index);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: AppColors.border, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(entry.key,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: AppColors.fgMuted)),
                                  ),
                                  Expanded(
                                    child: Text(entry.value,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _detectLanguage(String contentType) {
    if (contentType.contains('json')) return 'json';
    if (contentType.contains('xml')) return 'xml';
    if (contentType.contains('html')) return 'html';
    return 'plaintext';
  }

  String _prettyBody(String body, String contentType) {
    if (contentType.contains('json')) {
      try {
        return prettyJson(jsonDecode(body));
      } catch (_) {}
    }
    if (contentType.contains('xml')) {
      return prettyXml(body);
    }
    return body;
  }

  Future<void> _saveResponse(
      BuildContext context, HttpResponse response) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save response',
      fileName: 'response.txt',
    );
    if (path != null) {
      await File(path).writeAsBytes(response.bodyBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response saved')),
        );
      }
    }
  }
}

class _StatusTag extends StatelessWidget {
  final int statusCode;
  const _StatusTag({required this.statusCode});

  @override
  Widget build(BuildContext context) {
    final color = statusCode >= 200 && statusCode < 300
        ? AppColors.bgSuccess
        : statusCode >= 300 && statusCode < 400
            ? AppColors.bgInfo
            : statusCode >= 400 && statusCode < 500
                ? AppColors.bgWarning
                : AppColors.bgDanger;
    return Text(
      '$statusCode',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editors
// ---------------------------------------------------------------------------

class _KeyValueEditor extends StatefulWidget {
  final List<KeyValuePair> items;
  final ValueChanged<List<KeyValuePair>> onChanged;

  const _KeyValueEditor({required this.items, required this.onChanged});

  @override
  State<_KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<_KeyValueEditor> {
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, TextEditingController> _valueControllers = {};

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getKeyController(int index, String text) {
    if (!_keyControllers.containsKey(index)) {
      _keyControllers[index] = TextEditingController(text: text);
    }
    return _keyControllers[index]!;
  }

  TextEditingController _getValueController(int index, String text) {
    if (!_valueControllers.containsKey(index)) {
      _valueControllers[index] = TextEditingController(text: text);
    }
    return _valueControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.items.toList();
    return Column(
      children: [
        _SidebarRow(
          leading: const Icon(Icons.add, size: 16),
          title: const Text('Add', style: TextStyle(fontSize: 12)),
          onTap: () => widget.onChanged(
              [...rows, const KeyValuePair(key: '', value: '')]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.enabled,
                      onChanged: (v) {
                        rows[index] = item.copyWith(enabled: v ?? true);
                        widget.onChanged(rows);
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        decoration: const InputDecoration(
                            hintText: 'Key',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true),
                        controller: _getKeyController(index, item.key),
                        onChanged: (v) =>
                            rows[index] = item.copyWith(key: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        decoration: const InputDecoration(
                            hintText: 'Value',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true),
                        controller: _getValueController(index, item.value),
                        onChanged: (v) =>
                            rows[index] = item.copyWith(value: v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () {
                        _keyControllers.remove(index)?.dispose();
                        _valueControllers.remove(index)?.dispose();
                        rows.removeAt(index);
                        widget.onChanged(rows);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuthEditor extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const _AuthEditor({required this.auth, required this.onChanged});

  @override
  State<_AuthEditor> createState() => _AuthEditorState();
}

class _AuthEditorState extends State<_AuthEditor> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String field, String text) {
    if (!_controllers.containsKey(field)) {
      _controllers[field] = TextEditingController(text: text);
    }
    return _controllers[field]!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: auth.type,
          key: ValueKey(auth.type),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('None')),
            DropdownMenuItem(
                value: 'bearer', child: Text('Bearer Token')),
            DropdownMenuItem(
                value: 'basic', child: Text('Basic Auth')),
            DropdownMenuItem(
                value: 'apiKey', child: Text('API Key')),
            DropdownMenuItem(
                value: 'oauth2', child: Text('OAuth2')),
          ],
          onChanged: (type) {
            widget.onChanged(switch (type) {
              'bearer' => BearerAuth(token: ''),
              'basic' => BasicAuth(username: '', password: ''),
              'apiKey' => ApiKeyAuth(key: '', value: ''),
              'oauth2' => OAuth2Auth(
                  tokenUrl: '',
                  clientId: '',
                  clientSecret: '',
                  scope: ''),
              _ => const NoAuth(),
            });
          },
        ),
        Expanded(
          child: _buildAuthForm(),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    final auth = widget.auth;
    switch (auth) {
      case BearerAuth a:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            style:
                const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(labelText: 'Token'),
            controller: _controller('bearer.token', a.token),
            onChanged: (v) =>
                widget.onChanged(a.copyWith(token: v)),
          ),
        );
      case BasicAuth a:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration:
                    const InputDecoration(labelText: 'Username'),
                controller:
                    _controller('basic.username', a.username),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(username: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration:
                    const InputDecoration(labelText: 'Password'),
                obscureText: true,
                controller:
                    _controller('basic.password', a.password),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(password: v)),
              ),
            ],
          ),
        );
      case ApiKeyAuth a:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration:
                    const InputDecoration(labelText: 'Key'),
                controller: _controller('apiKey.key', a.key),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(key: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration:
                    const InputDecoration(labelText: 'Value'),
                controller:
                    _controller('apiKey.value', a.value),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(value: v)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ApiKeyLocation>(
                initialValue: a.location,
                key: ValueKey(a.location),
                items: ApiKeyLocation.values
                    .map((l) => DropdownMenuItem(
                        value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (l) {
                  if (l != null) {
                    widget.onChanged(a.copyWith(location: l));
                  }
                },
              ),
            ],
          ),
        );
      case OAuth2Auth a:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                    labelText: 'Token URL'),
                controller:
                    _controller('oauth2.tokenUrl', a.tokenUrl),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(tokenUrl: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                    labelText: 'Client ID'),
                controller:
                    _controller('oauth2.clientId', a.clientId),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(clientId: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                    labelText: 'Client Secret'),
                obscureText: true,
                controller: _controller(
                    'oauth2.clientSecret', a.clientSecret),
                onChanged: (v) => widget
                    .onChanged(a.copyWith(clientSecret: v)),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12),
                decoration:
                    const InputDecoration(labelText: 'Scope'),
                controller:
                    _controller('oauth2.scope', a.scope),
                onChanged: (v) =>
                    widget.onChanged(a.copyWith(scope: v)),
              ),
            ],
          ),
        );
      default:
        return const Center(
          child: Text('No authentication',
              style:
                  TextStyle(color: AppColors.fgMuted, fontSize: 12)),
        );
    }
  }
}

class _BodyEditor extends StatefulWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  const _BodyEditor({required this.body, required this.onChanged});

  @override
  State<_BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends State<_BodyEditor> {
  late TextEditingController _rawContentController;

  @override
  void initState() {
    super.initState();
    _rawContentController =
        TextEditingController(text: widget.body.rawContent);
  }

  @override
  void dispose() {
    _rawContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.body;
    return Column(
      children: [
        DropdownButtonFormField<BodyMode>(
          initialValue: body.mode,
          key: ValueKey(body.mode),
          items: BodyMode.values
              .map((m) => DropdownMenuItem(
                  value: m, child: Text(m.displayName)))
              .toList(),
          onChanged: (m) {
            if (m != null) widget.onChanged(body.copyWith(mode: m));
          },
        ),
        if (body.mode == BodyMode.raw) ...[
          DropdownButtonFormField<RawContentType>(
            initialValue: body.rawContentType,
            key: ValueKey(body.rawContentType),
            items: RawContentType.values
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(t.displayName)))
                .toList(),
            onChanged: (t) {
              if (t != null) {
                widget.onChanged(body.copyWith(rawContentType: t));
              }
            },
          ),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Body content',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              controller: _rawContentController,
              onChanged: (v) =>
                  widget.onChanged(body.copyWith(rawContent: v)),
            ),
          ),
        ] else if (body.mode == BodyMode.formData ||
            body.mode == BodyMode.urlEncoded) ...[
          Expanded(
            child: _KeyValueEditor(
              items: body.formData,
              onChanged: (v) =>
                  widget.onChanged(body.copyWith(formData: v)),
            ),
          ),
        ] else
          const Center(
            child: Text('No body',
                style: TextStyle(
                    color: AppColors.fgMuted, fontSize: 12)),
          ),
      ],
    );
  }
}

class _ScriptsEditor extends StatefulWidget {
  final RequestScripts scripts;
  final ValueChanged<RequestScripts> onChanged;

  const _ScriptsEditor({required this.scripts, required this.onChanged});

  @override
  State<_ScriptsEditor> createState() => _ScriptsEditorState();
}

class _ScriptsEditorState extends State<_ScriptsEditor> {
  late TextEditingController _preScriptController;
  late TextEditingController _postScriptController;

  @override
  void initState() {
    super.initState();
    _preScriptController =
        TextEditingController(text: widget.scripts.preRequest);
    _postScriptController =
        TextEditingController(text: widget.scripts.postResponse);
  }

  @override
  void dispose() {
    _preScriptController.dispose();
    _postScriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Pre-request'),
            Tab(text: 'Post-response'),
          ]),
          Expanded(
            child: Container(
              color: AppColors.paneBg,
              child: TabBarView(
                children: [
                  TextField(
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '// variables["key"] = "value";',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    controller: _preScriptController,
                    onChanged: (v) => widget.onChanged(
                        widget.scripts.copyWith(preRequest: v)),
                  ),
                  TextField(
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          '// test("status 200", response["statusCode"] == 200);',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    controller: _postScriptController,
                    onChanged: (v) => widget.onChanged(
                        widget.scripts.copyWith(postResponse: v)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
