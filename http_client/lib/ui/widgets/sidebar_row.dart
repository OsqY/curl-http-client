import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/click_cursor.dart';

/// Sidebar row — replaces ListTile, no ListTile warnings.
class SidebarRow extends ConsumerWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double leftPadding;

  SidebarRow({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.onTap,
    this.onSecondaryTap,
    this.leftPadding = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorSetProvider);
    return ClickCursor(
      child: GestureDetector(
        onSecondaryTapDown: onSecondaryTap != null
            ? (d) => onSecondaryTap!()
            : null,
        child: InkWell(
          onTap: onTap,
          hoverColor: colors.border.withAlpha(40),
          highlightColor: colors.border.withAlpha(60),
          child: Container(
            padding: EdgeInsets.only(
              left: leftPadding,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, SizedBox(width: 6)],
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: colors.text,
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
