import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/sidebar.dart';

void main() {
  testWidgets('Sidebar renders with theme switcher', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: Sidebar(
              onRequestSelected: null,
              onMenuAction: null,
            ),
          ),
        ),
      ),
    );

    // Verify sidebar renders
    expect(find.byType(Sidebar), findsOneWidget);
  });
}
