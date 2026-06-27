import 'package:flutter_test/flutter_test.dart';
import 'package:http_client/ui/app.dart';

void main() {
  testWidgets('App renders main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HttpClientApp());
    expect(find.text('HTTP Client'), findsOneWidget);
  });
}
