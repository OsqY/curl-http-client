import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/ui/theme/app_theme.dart';
import 'package:http_client/ui/widgets/request_editor.dart';

void main() {
  testWidgets('RequestEditor renders with URL bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: RequestEditor(onSend: () {}, onSave: () {}),
          ),
        ),
      ),
    );

    expect(find.byType(RequestEditor), findsOneWidget);
  });
}
