import 'package:flutter/material.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';

/// Colored badge for HTTP methods, matching Insomnia's style.
class MethodBadge extends StatelessWidget {
  final HttpMethod method;
  final double fontSize;

  const MethodBadge({super.key, required this.method, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        method.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  static Color _methodColor(HttpMethod method) {
    return switch (method) {
      HttpMethod.get => AppColors.bgSuccess,
      HttpMethod.post => AppColors.bgNotice,
      HttpMethod.put => AppColors.bgWarning,
      HttpMethod.patch => AppColors.bgSurprise,
      HttpMethod.delete => AppColors.bgDanger,
      HttpMethod.head => AppColors.bgInfo,
      HttpMethod.options => AppColors.bgInfo,
    };
  }
}
