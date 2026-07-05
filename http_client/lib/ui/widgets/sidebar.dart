import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/providers/app_state.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/widgets.dart';
import 'package:http_client/ui/widgets/sidebar_dialogs.dart';

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
    final colors = ref.watch(colorSetProvider);
    final collectionsAsync = ref.watch(collectionsProvider);
    final historyAsync = ref.watch(historyProvider);
    final envsAsync = ref.watch(environmentsProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final historySearch = ref.watch(historySearchProvider);
    final dialogs = SidebarDialogs(ref, colors);

    return Column(
      children: [
        // Workspace header
        Container(
          width: double.infinity,
          color: colors.elevated,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                'HTTP Client',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              ClickCursor(
                child: PopupMenuButton<SootThemeVariant>(
                  onSelected: (v) =>
                      ref.read(themeVariantProvider.notifier).setTheme(v),
                  icon: Icon(
                    Icons.palette_outlined,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  tooltip: 'Theme',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SootThemeVariant.dark,
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode, size: 16),
                          SizedBox(width: 8),
                          Text('Soot Dark'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SootThemeVariant.light,
                      child: Row(
                        children: [
                          Icon(Icons.light_mode, size: 16),
                          SizedBox(width: 8),
                          Text('Soot Light'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SootThemeVariant.orange,
                      child: Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Soot Orange'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      ref
                          .read(currentRequestProvider.notifier)
                          .state = HttpRequest(
                        id: HttpRequest.generateId(),
                        name: 'Untitled',
                        method: HttpMethod.get,
                        url: 'https://httpbin.org/get',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 14, color: colors.textMuted),
                          SizedBox(width: 4),
                          Text(
                            'New Request',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'clear_cookies') {
                    ref.read(cookieJarProvider.notifier).clearCookies();
                  } else {
                    onMenuAction(v);
                  }
                },
                icon: Icon(Icons.more_vert, size: 16, color: colors.textMuted),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'import_curl',
                    child: Text('Import curl'),
                  ),
                  PopupMenuItem(
                    value: 'import_openapi',
                    child: Text('Import OpenAPI'),
                  ),
                  PopupMenuItem(
                    value: 'export_curl',
                    child: Text('Export curl'),
                  ),
                  PopupMenuItem(
                    value: 'export_openapi',
                    child: Text('Export OpenAPI'),
                  ),
                  PopupMenuItem(
                    value: 'change_workspace',
                    child: Text('Change workspace'),
                  ),
                  PopupMenuItem(
                    value: 'clear_cookies',
                    child: Text('Clear cookies'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1),
        // Environment selector + actions
        envsAsync.when(
          data: (envs) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                ClickCursor(
                  child: IconButton(
                    icon: Icon(Icons.add, size: 14),
                    tooltip: 'New environment',
                    onPressed: () => dialogs.showEnvironmentDialog(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ),
                Expanded(
                  child: ClickCursor(
                    child: DropdownMenu<Environment?>(
                      initialSelection: activeEnv,
                      expandedInsets: EdgeInsets.zero,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: null,
                          label: 'No environment',
                        ),
                        ...envs.map(
                          (env) => DropdownMenuEntry(
                            value: env,
                            label: env.name,
                          ),
                        ),
                      ],
                      onSelected: (v) =>
                          ref.read(activeEnvironmentProvider.notifier).state = v,
                    ),
                  ),
                ),
                if (activeEnv != null) ...[
                  ClickCursor(
                    child: IconButton(
                      icon: Icon(Icons.edit, size: 14),
                      tooltip: 'Edit environment',
                      onPressed: () =>
                          dialogs.showEnvironmentDialog(context, activeEnv),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        dialogs.confirmDeleteEnvironment(context, activeEnv);
                      }
                    },
                    icon: Icon(
                      Icons.more_vert,
                      size: 14,
                      color: colors.textMuted,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete environment'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Divider(height: 1),
        // Collections
        Expanded(
          child: collectionsAsync.when(
            data: (collections) => ListView(
              padding: EdgeInsets.zero,
              children: [
                // New collection button
                SidebarRow(
                  leading: Icon(Icons.create_new_folder, size: 16),
                  title: Text(
                    'New Collection',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  onTap: () => dialogs.showCollectionDialog(context),
                ),
                ...collections.expand((collection) {
                  return [
                    // Collection header with hover actions
                    CollectionHeader(
                      collection: collection,
                      onRename: () =>
                          dialogs.showCollectionDialog(context, collection),
                      onDelete: () =>
                          dialogs.confirmDeleteCollection(context, collection),
                      onNewFolder: () =>
                          dialogs.showFolderDialog(context, collection),
                    ),
                    // Folders
                    ...collection.folders.map(
                      (folder) => SidebarRow(
                        leading: Icon(Icons.folder_open, size: 16),
                        title: Text(
                          folder.name,
                          style: TextStyle(fontSize: 12),
                        ),
                        leftPadding: 24,
                        onSecondaryTap: () => dialogs.showFolderContextMenu(
                          context,
                          collection,
                          folder,
                        ),
                      ),
                    ),
                    // Requests in collection
                    FutureBuilder<List<HttpRequest>>(
                      future: ref
                          .read(workspaceRepositoryProvider)
                          .loadAllRequests(collection.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return Column(
                          children: snapshot.data!
                              .map(
                                (req) => SidebarRow(
                                  leading: MethodBadge(method: req.method),
                                  title: Text(
                                    req.name,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  leftPadding: 24,
                                  onTap: () => onRequestSelected(req),
                                  onSecondaryTap: () =>
                                      dialogs.showRequestContextMenu(
                                        context,
                                        collection,
                                        req,
                                      ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ];
                }),
              ],
            ),
            loading: () =>
                Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Divider(height: 1),
        // History section
        SectionHeader(title: 'History'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ClickCursor(
            child: InkWell(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Delete all history entries?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // History is read-only from workspace, clearing requires
                  // deleting all history files. For now, just show a message.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 12,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            style: TextStyle(color: colors.text, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search history...',
              hintStyle: TextStyle(color: colors.textPlaceholder, fontSize: 12),
              prefixIcon: Icon(Icons.search, size: 14, color: colors.textMuted),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.borderFocused),
              ),
              filled: true,
              fillColor: colors.surface,
            ),
            onChanged: (value) {
              ref.read(historySearchProvider.notifier).state = value;
            },
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (entries) {
              final filtered = historySearch.isEmpty
                  ? entries
                  : entries
                        .where(
                          (e) =>
                              e.request.url.toLowerCase().contains(
                                historySearch.toLowerCase(),
                              ) ||
                              e.request.name.toLowerCase().contains(
                                historySearch.toLowerCase(),
                              ) ||
                              e.statusCode.toString().contains(historySearch),
                        )
                        .toList();
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  return SidebarRow(
                    leading: MethodBadge(method: entry.request.method),
                    title: Text(
                      entry.request.url,
                      style: TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${entry.statusCode} • ${entry.durationMs}ms',
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                    ),
                    onTap: () => onRequestSelected(entry.request),
                  );
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
