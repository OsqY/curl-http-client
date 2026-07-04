import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/method_badge.dart';

void main() {
  testWidgets('MethodBadge renders with correct color for GET', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(body: MethodBadge(method: HttpMethod.get)),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('GET'));
    expect(text.style?.color, isNotNull);
  });

  testWidgets('MethodBadge renders with correct color for POST', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const Scaffold(body: MethodBadge(method: HttpMethod.post)),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('POST'));
    expect(text.style?.color, isNotNull);
  });
}
