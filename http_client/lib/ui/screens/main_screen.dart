import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/widgets.dart';
import 'package:http_client/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Clickable wrapper — shows hand cursor on desktop

// Sidebar row — replaces ListTile, no warnings

// Main Screen

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
                  child: Sidebar(
                    onRequestSelected: (req) {
                      ref.read(currentRequestProvider.notifier).state = req;
                    },
                    onMenuAction: _handleMenuAction,
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
                            child: ResponsePanel(),
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'import_curl':
        _importCurl();
      case 'import_openapi':
        _importOpenApi();
      case 'export_curl':
        _exportCurl();
      case 'export_openapi':
        _exportOpenApi();
      case 'change_workspace':
        _changeWorkspace();
    }
  }

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

// Sidebar

// Request Editor

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
              ClickCursor(
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
              ClickCursor(
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
              ClickCursor(
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
                        KeyValueEditor(
                          items: request.queryParams,
                          onChanged: (v) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(queryParams: v);
                          },
                        ),
                        KeyValueEditor(
                          items: request.headers,
                          onChanged: (v) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(headers: v);
                          },
                        ),
                        AuthEditor(
                          auth: request.auth,
                          onChanged: (a) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(auth: a);
                          },
                        ),
                        BodyEditor(
                          body: request.body,
                          onChanged: (b) {
                            ref.read(unsavedChangesProvider.notifier).state = true;
                            ref.read(currentRequestProvider.notifier).state =
                                request.copyWith(body: b);
                          },
                        ),
                        ScriptsEditor(
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

// Response Panel

