import 'package:flutter/material.dart';

/// Clickable wrapper — shows hand cursor on desktop.
class ClickCursor extends StatelessWidget {
  final Widget child;
  const ClickCursor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: child);
  }
}
