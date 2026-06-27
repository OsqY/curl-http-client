import 'package:flutter/material.dart';
import 'package:http_client/ui/theme/app_theme.dart';

/// Section header with uppercase label used in the sidebar.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.paneHeaderBg,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.fgMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
