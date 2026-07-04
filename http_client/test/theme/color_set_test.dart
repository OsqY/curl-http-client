import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:http_client/ui/theme/app_theme.dart';

void main() {
  group('ColorSet', () {
    test('dark theme has correct background', () {
      expect(ColorSet.dark.bg, const Color(0xFF0C0C0E));
    });

    test('light theme has correct background', () {
      expect(ColorSet.light.bg, const Color(0xFFFAFAFA));
    });

    test('orange theme has correct accent', () {
      expect(ColorSet.orangeDark.accent, const Color(0xFFFF6A00));
    });

    test('all color sets have required properties', () {
      for (final colors in [
        ColorSet.dark,
        ColorSet.light,
        ColorSet.orangeDark,
      ]) {
        expect(colors.bg, isNotNull);
        expect(colors.surface, isNotNull);
        expect(colors.text, isNotNull);
        expect(colors.accent, isNotNull);
      }
    });
  });
}
