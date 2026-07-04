import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/status_tag.dart';

void main() {
  testWidgets('StatusTag renders 200 in green', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: StatusTag(statusCode: 200),
          ),
        ),
      ),
    );

    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('StatusTag renders 404 in amber', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: StatusTag(statusCode: 404),
          ),
        ),
      ),
    );

    expect(find.text('404'), findsOneWidget);
  });

  testWidgets('StatusTag renders 500 in red', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(
            body: StatusTag(statusCode: 500),
          ),
        ),
      ),
    );

    expect(find.text('500'), findsOneWidget);
  });
}
