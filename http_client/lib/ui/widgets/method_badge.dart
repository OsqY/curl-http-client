import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/providers/app_state.dart';

/// Colored badge for HTTP methods, matching Insomnia's style.
class MethodBadge extends ConsumerWidget {
  final HttpMethod method;
  final double fontSize;

  MethodBadge({super.key, required this.method, this.fontSize = 11});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorSetProvider);
    final color = _methodColor(method, colors);
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

  Color _methodColor(HttpMethod method, ColorSet colors) {
    return switch (method) {
      HttpMethod.get => colors.green,
      HttpMethod.post => colors.amber,
      HttpMethod.put => colors.amber,
      HttpMethod.patch => colors.steelBlue,
      HttpMethod.delete => colors.accent,
      HttpMethod.head => colors.steelBlue,
      HttpMethod.options => colors.steelBlue,
    };
  }
}
