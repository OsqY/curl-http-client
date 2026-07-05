import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/click_cursor.dart';

/// Header row for a collection in the sidebar with rename/delete/folder actions.
/// Also acts as a DragTarget for moving requests between collections.
class CollectionHeader extends ConsumerStatefulWidget {
  final RequestCollection collection;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onNewFolder;
  final VoidCallback onToggle;
  final bool isExpanded;
  final void Function(HttpRequest request)? onRequestDropped;
  final bool isDragTarget;

  const CollectionHeader({
    super.key,
    required this.collection,
    required this.onRename,
    required this.onDelete,
    required this.onNewFolder,
    required this.onToggle,
    required this.isExpanded,
    this.onRequestDropped,
    this.isDragTarget = true,
  });

  @override
  ConsumerState<CollectionHeader> createState() => _CollectionHeaderState();
}

class _CollectionHeaderState extends ConsumerState<CollectionHeader> {
  bool _hovering = false;
  bool _dragHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorSetProvider);
    final bgColor = _dragHovering ? colors.hover : colors.elevated;

    Widget header = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: bgColor,
        child: Row(
          children: [
            ClickCursor(
              child: InkWell(
                onTap: widget.onToggle,
                child: Icon(
                  widget.isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 14,
                  color: colors.textMuted,
                ),
              ),
            ),
            Icon(Icons.folder, size: 14, color: colors.textMuted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.collection.name,
                style: TextStyle(
                  color: colors.textMuted,
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
                  icon: Icon(Icons.add, size: 14),
                  tooltip: 'New folder',
                  onPressed: widget.onNewFolder,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              ClickCursor(
                child: IconButton(
                  icon: Icon(Icons.edit, size: 14),
                  tooltip: 'Rename',
                  onPressed: widget.onRename,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
              ClickCursor(
                child: IconButton(
                  icon: Icon(Icons.delete, size: 14),
                  tooltip: 'Delete',
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.isDragTarget && widget.onRequestDropped != null) {
      header = DragTarget<HttpRequest>(
        onWillAcceptWithDetails: (details) {
          setState(() => _dragHovering = true);
          return true;
        },
        onLeave: (_) => setState(() => _dragHovering = false),
        onAcceptWithDetails: (details) {
          setState(() => _dragHovering = false);
          widget.onRequestDropped!(details.data);
        },
        builder: (context, candidates, rejected) => header,
      );
    }

    return header;
  }
}
