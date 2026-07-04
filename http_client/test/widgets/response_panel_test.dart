import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/response_panel.dart';

void main() {
  testWidgets('ResponsePanel renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: ResponsePanel(),
          ),
        ),
      ),
    );

    // Verify response panel renders
    expect(find.byType(ResponsePanel), findsOneWidget);
    expect(find.text('Send a request to see the response'), findsOneWidget);
  });
}
