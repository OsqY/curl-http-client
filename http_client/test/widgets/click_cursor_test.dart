import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http_client/ui/widgets/click_cursor.dart';

void main() {
  testWidgets('ClickCursor shows hand cursor on hover', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClickCursor(
            child: Text('Click me'),
          ),
        ),
      ),
    );

    expect(find.text('Click me'), findsOneWidget);
    
    // Verify MouseRegion is present
    final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
    expect(mouseRegion.cursor, SystemMouseCursors.click);
  });
}
