import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/models/models.dart';
import 'package:http_client/ui/widgets/widgets.dart';

void main() {
  // -------------------------------------------------------------------------
  // StatusTag
  // -------------------------------------------------------------------------
  group('StatusTag', () {
    testWidgets('renders status code text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatusTag(statusCode: 200))),
      );
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('uses success color for 2xx', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatusTag(statusCode: 200))),
      );
      final text = tester.widget<Text>(find.text('200'));
      expect(text.style?.color?.toARGB32(), 0xFF7ECF2B);
    });

    testWidgets('uses warning color for 4xx', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatusTag(statusCode: 404))),
      );
      final text = tester.widget<Text>(find.text('404'));
      expect(text.style?.color?.toARGB32(), 0xFFFF9A1F);
    });

    testWidgets('uses danger color for 5xx', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatusTag(statusCode: 500))),
      );
      final text = tester.widget<Text>(find.text('500'));
      expect(text.style?.color?.toARGB32(), 0xFFFF5631);
    });

    testWidgets('uses info color for 3xx', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatusTag(statusCode: 301))),
      );
      final text = tester.widget<Text>(find.text('301'));
      expect(text.style?.color?.toARGB32(), 0xFF46C1E6);
    });
  });

  // -------------------------------------------------------------------------
  // ClickCursor
  // -------------------------------------------------------------------------
  group('ClickCursor', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClickCursor(child: Text('Click me'))),
        ),
      );
      expect(find.text('Click me'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // SidebarRow
  // -------------------------------------------------------------------------
  group('SidebarRow', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SidebarRow(title: const Text('My Item'))),
        ),
      );
      expect(find.text('My Item'), findsOneWidget);
    });

    testWidgets('renders leading icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarRow(
              leading: const Icon(Icons.star),
              title: const Text('Item'),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarRow(
              title: const Text('Item'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SidebarRow(
              title: const Text('Clickable'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clickable'));
      expect(tapped, true);
    });
  });

  // -------------------------------------------------------------------------
  // MethodBadge
  // -------------------------------------------------------------------------
  group('MethodBadge', () {
    testWidgets('renders HTTP method text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MethodBadge(method: HttpMethod.get)),
        ),
      );
      expect(find.text('GET'), findsOneWidget);
    });

    testWidgets('renders POST method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MethodBadge(method: HttpMethod.post)),
        ),
      );
      expect(find.text('POST'), findsOneWidget);
    });
  });
}
