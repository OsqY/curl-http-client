import 'package:flutter/material.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/click_cursor.dart';

/// Header row for a collection in the sidebar with rename/delete/folder actions.
class CollectionHeader extends StatefulWidget {
  final RequestCollection collection;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onNewFolder;

  const CollectionHeader({
    super.key,
    required this.collection,
    required this.onRename,
    required this.onDelete,
    required this.onNewFolder,
  });

  @override
  State<CollectionHeader> createState() => _CollectionHeaderState();
}

class _CollectionHeaderState extends State<CollectionHeader> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: AppColors.elevated,
        child: Row(
          children: [
            const Icon(Icons.folder, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.collection.name,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hovering) ...[
              ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  tooltip: 'New folder',
                  onPressed: widget.onNewFolder,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              ClickCursor(
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 14),
                  tooltip: 'Rename',
                  onPressed: widget.onRename,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              ClickCursor(
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
