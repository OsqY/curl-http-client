import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/widgets.dart';

/// Request editor with name field, URL bar, method selector, and tabbed editor panels.
class RequestEditor extends ConsumerStatefulWidget {
  final VoidCallback onSend;
  final VoidCallback onSave;

  const RequestEditor({
    super.key,
    required this.onSend,
    required this.onSave,
  });

  @override
  ConsumerState<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends ConsumerState<RequestEditor> {
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
          color: AppColors.elevated,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: AppColors.text,
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
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                    child: Icon(Icons.circle, size: 6, color: AppColors.amber),
                  ),
                ),
            ],
          ),
        ),
        // URL bar
        Container(
          color: AppColors.elevated,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MethodBadge(method: request.method),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 14, color: AppColors.textMuted),
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
                      color: AppColors.green,
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
                    color: AppColors.surface,
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
                                    color: AppColors.textMuted, fontSize: 12)),
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
