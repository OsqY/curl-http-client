import 'package:flutter/material.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/click_cursor.dart';

/// Sidebar row — replaces ListTile, no ListTile warnings.
class SidebarRow extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final double leftPadding;

  const SidebarRow({
    super.key,
    this.leading,
    this.title,
    this.trailing,
    this.onTap,
    this.onSecondaryTap,
    this.leftPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClickCursor(
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
              left: leftPadding,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.text,
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
