import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';

/// Dialog and context menu methods extracted from Sidebar.
/// Takes WidgetRef and ColorSet as constructor parameters.
class SidebarDialogs {
  final WidgetRef ref;
  final ColorSet colors;

  SidebarDialogs(this.ref, this.colors);

  // ---- Collection dialogs ----

  Future<void> showCollectionDialog(
    BuildContext context, [
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
      await ref
          .read(collectionsProvider.notifier)
          .save(RequestCollection(id: HttpRequest.generateId(), name: result));
    }
  }

  Future<void> confirmDeleteCollection(
    BuildContext context,
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
      await ref.read(collectionsProvider.notifier).delete(collection.id);
    }
  }

  // ---- Folder dialogs ----

  Future<void> showFolderDialog(
    BuildContext context,
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
      folders.add(RequestFolder(id: HttpRequest.generateId(), name: result));
    }
    await ref
        .read(collectionsProvider.notifier)
        .save(collection.copyWith(folders: folders));
  }

  void showFolderContextMenu(
    BuildContext context,
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
            parentFolderId: folder.id,
            collectionId: collection.id,
          );
        case 'rename':
          showFolderDialog(context, collection, folder);
        case 'delete':
          confirmDeleteFolder(context, collection, folder);
      }
    });
  }

  Future<void> confirmDeleteFolder(
    BuildContext context,
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

  // ---- Request dialogs ----

  void showRequestContextMenu(
    BuildContext context,
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
          duplicateRequest(collection, request);
        case 'rename':
          showRequestRenameDialog(context, collection, request);
        case 'delete':
          confirmDeleteRequest(context, collection, request);
      }
    });
  }

  void duplicateRequest(
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

  Future<void> showRequestRenameDialog(
    BuildContext context,
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

  Future<void> confirmDeleteRequest(
    BuildContext context,
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

  Future<void> showEnvironmentDialog(
    BuildContext context, [
    Environment? existing,
  ]) async {
    final nameController = TextEditingController(
      text: existing?.name ?? 'New Env',
    );
    final vars =
        existing?.variables.toList() ??
        [const EnvironmentVariable(key: '', value: '')];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New Environment' : 'Edit Environment'),
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
                            decoration: const InputDecoration(labelText: 'Key'),
                            onChanged: (v) =>
                                vars[index] = vars[index].copyWith(key: v),
                            controller: TextEditingController(
                              text: vars[index].key,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Value',
                            ),
                            onChanged: (v) =>
                                vars[index] = vars[index].copyWith(value: v),
                            controller: TextEditingController(
                              text: vars[index].value,
                            ),
                            obscureText: vars[index].secret,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            vars[index].secret
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => vars[index] = vars[index].copyWith(
                            secret: !vars[index].secret,
                          ),
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
                variables: vars.where((v) => v.key.isNotEmpty).toList(),
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

  Future<void> confirmDeleteEnvironment(
    BuildContext context,
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
