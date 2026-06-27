import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/widgets.dart';

/// Sidebar with collections tree, environment selector, and history.
class Sidebar extends ConsumerWidget {
  final void Function(HttpRequest) onRequestSelected;
  final void Function(String action) onMenuAction;

  const Sidebar({
    super.key,
    required this.onRequestSelected,
    required this.onMenuAction,
  });

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
                child: ClickCursor(
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
                  if (v == 'clear_cookies') {
                    ref.read(cookieJarProvider.notifier).clearCookies();
                  } else {
                    onMenuAction(v);
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
                ClickCursor(
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
                  ClickCursor(
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
                SidebarRow(
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
                    CollectionHeader(
                      collection: collection,
                      onRename: () => _showCollectionDialog(
                          context, ref, collection),
                      onDelete: () =>
                          _confirmDeleteCollection(context, ref, collection),
                      onNewFolder: () =>
                          _showFolderDialog(context, ref, collection),
                    ),
                    // Folders
                    ...collection.folders.map((folder) => SidebarRow(
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
                              .map((req) => SidebarRow(
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
        SectionHeader(title: 'History'),
        Expanded(
          child: historyAsync.when(
            data: (entries) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return SidebarRow(
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
