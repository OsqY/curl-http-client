import 'package:flutter/material.dart';
import 'package:http_client/ui/theme/app_theme.dart';

/// Displays an HTTP status code with color-coded severity.
class StatusTag extends StatelessWidget {
  final int statusCode;

  const StatusTag({super.key, required this.statusCode});

  @override
  Widget build(BuildContext context) {
    final color = statusCode >= 200 && statusCode < 300
        ? AppColors.green
        : statusCode >= 300 && statusCode < 400
        ? AppColors.steelBlue
        : statusCode >= 400 && statusCode < 500
        ? AppColors.amber
        : AppColors.accent;
    return Text(
      '$statusCode',
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    );
  }
}
