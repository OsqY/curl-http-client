import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/providers/app_state.dart';

/// Displays an HTTP status code with color-coded severity.
class StatusTag extends ConsumerWidget {
  final int statusCode;

  const StatusTag({super.key, required this.statusCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorSetProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final color = statusCode >= 200 && statusCode < 300
        ? colors.green
        : statusCode >= 300 && statusCode < 400
        ? colors.steelBlue
        : statusCode >= 400 && statusCode < 500
        ? colors.amber
        : colors.accent;
    return Text(
      '$statusCode',
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    );
  }
}
