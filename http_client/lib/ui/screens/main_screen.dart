import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
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
  double _topPanelHeight = 300;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkspace();
    });
  }

  Future<void> _loadWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('workspace_path');
    if (savedPath != null && savedPath.isNotEmpty) {
      await _openWorkspace(savedPath);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final workspacePath = '${dir.path}/http_client_workspace';
      await _openWorkspace(workspacePath);
    }
  }

  Future<void> _changeWorkspace() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select workspace directory',
    );
    if (path != null) {
      await _openWorkspace(path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('workspace_path', path);
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
    final colors = ref.watch(colorSetProvider);
    final workspacePath = ref.watch(workspacePathProvider);
    final currentRequest = ref.watch(currentRequestProvider);

    // Update window title when request changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final title = currentRequest.name.isNotEmpty
          ? currentRequest.name
          : 'HTTP Client';
      windowManager.setTitle('$title — HTTP Client');
    });

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
                  color: colors.surface,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final totalHeight = constraints.maxHeight;
                          final topHeight = _topPanelHeight.clamp(
                            200.0,
                            totalHeight - 200.0,
                          );
                          return Column(
                            children: [
                              SizedBox(
                                height: topHeight,
                                child: RequestEditor(
                                  onSend: _sendRequest,
                                  onSave: _saveRequest,
                                ),
                              ),
                              GestureDetector(
                                onVerticalDragUpdate: (details) {
                                  setState(() {
                                    _topPanelHeight += details.delta.dy;
                                  });
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeRow,
                                  child: Container(
                                    height: 6,
                                    color: colors.border,
                                    child: Center(
                                      child: Container(
                                        height: 2,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: colors.textMuted,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: ResponsePanel()),
                            ],
                          );
                        },
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
              request.scripts.preRequest,
              request,
              effectiveVariables,
            );
        effectiveVariables = Map<String, String>.from(scriptResult.variables);
        if (scriptResult.errors.isNotEmpty) {
          ref.read(scriptOutputProvider.notifier).state =
              'Pre-request script errors:\n${scriptResult.errors.join('\n')}';
        } else if (scriptResult.assertions.isNotEmpty) {
          ref.read(scriptOutputProvider.notifier).state = scriptResult
              .assertions
              .join('\n');
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
          .execute(
            request,
            variables: effectiveVariables,
            accessToken: accessToken,
          );

      if (result.error != null) {
        ref.read(executionErrorProvider.notifier).state = result.error;
      } else if (result.response != null) {
        final response = result.response!;
        ref.read(responseProvider.notifier).state = response;

        if (request.scripts.postResponse.isNotEmpty) {
          final scriptResult = await ref
              .read(scriptingServiceProvider)
              .runPostResponse(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request saved')));
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
      final request = ref.read(importExportServiceProvider).parseCurl(result);
      ref.read(currentRequestProvider.notifier).state = request;
      // Auto-save imported request to first collection
      final collections = ref.read(collectionsProvider).valueOrNull ?? [];
      if (collections.isNotEmpty) {
        await ref
            .read(workspaceRepositoryProvider)
            .saveRequest(request, collections.first.id);
        await ref.read(collectionsProvider.notifier).load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
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
      final isYaml = file.files.first.extension?.toLowerCase() != 'json';
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
            content: Text('Imported ${importResult.requests.length} requests'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('OpenAPI import failed: $e')));
      }
    }
  }

  void _exportCurl() async {
    final request = ref.read(currentRequestProvider);
    final script = ref.read(importExportServiceProvider).exportCurl([request]);
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
