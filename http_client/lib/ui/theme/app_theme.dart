import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_client/providers/app_state.dart';

/// Soot theme color palette — monochrome-dominant, dot-matrix-inspired,
/// with sparse signal accents (Nothing Technology design language).
class AppColors {
  AppColors._();

  // ── Background hierarchy ─────────────────────────────────
  static const bg = Color(0xFF0C0C0E);
  static const surface = Color(0xFF161618);
  static const elevated = Color(0xFF1C1C20);
  static const hover = Color(0xFF202023);
  static const active = Color(0xFF2A2A2E);

  // ── Text ─────────────────────────────────────────────────
  static const text = Color(0xFFE9E9EB);
  static const textMuted = Color(0xFF8A8A8E);
  static const textPlaceholder = Color(0xFF515154);
  static const textDisabled = Color(0xFF515154);

  // ── Borders ──────────────────────────────────────────────
  static const border = Color(0xFF3A3A3D);
  static const borderVariant = Color(0xFF232327);
  static const borderFocused = Color(0xFFE10F1C);
  static const borderSelected = Color(0xFF6C0D14);

  // ── Accents ──────────────────────────────────────────────
  static const accent = Color(0xFFE10F1C);
  static const amber = Color(0xFFD9A441);
  static const green = Color(0xFF8AB36C);
  static const steelBlue = Color(0xFF7FA6B8);
  static const lightSteel = Color(0xFFAEBBCB);
  static const warmTan = Color(0xFFC9B9A6);
  static const mutedGrey = Color(0xFF5D636F);
  static const punctuationGrey = Color(0xFF8A8E96);

  // ── HTTP Status ──────────────────────────────────────────
  static const statusSuccess = Color(0xFF8AB36C);
  static const statusRedirect = Color(0xFF7FA6B8);
  static const statusClientError = Color(0xFFD9A441);
  static const statusServerError = Color(0xFFE10F1C);

  // ── Scrollbar ────────────────────────────────────────────
  static const scrollbarThumb = Color(0x2EE9E9EB);
  static const scrollbarThumbHover = Color(0xFF4B4B4D);

  // ── Diff ─────────────────────────────────────────────────
  static const diffInsert = Color(0xFF8AB36C);
  static const diffInsertBg = Color(0x408AB36C);
  static const diffDelete = Color(0xFFE10F1C);
  static const diffDeleteBg = Color(0x40E10F1C);
}

/// Active color set based on current theme variant.
final colorSetProvider = Provider<ColorSet>((ref) {
  final variant = ref.watch(themeVariantProvider);
  return switch (variant) {
    SootThemeVariant.dark => ColorSet.dark,
    SootThemeVariant.light => ColorSet.light,
    SootThemeVariant.orange => ColorSet.orangeDark,
  };
});

/// A complete set of Soot color tokens for one theme variant.
class ColorSet {
  final Color bg, surface, elevated, hover, active;
  final Color text, textMuted, textPlaceholder, textDisabled;
  final Color border, borderVariant, borderFocused, borderSelected;
  final Color accent,
      amber,
      green,
      steelBlue,
      lightSteel,
      warmTan,
      mutedGrey,
      punctuationGrey;
  final Color statusSuccess,
      statusRedirect,
      statusClientError,
      statusServerError;
  final Color scrollbarThumb, scrollbarThumbHover;
  final Color diffInsert, diffInsertBg, diffDelete, diffDeleteBg;

  const ColorSet({
    required this.bg,
    required this.surface,
    required this.elevated,
    required this.hover,
    required this.active,
    required this.text,
    required this.textMuted,
    required this.textPlaceholder,
    required this.textDisabled,
    required this.border,
    required this.borderVariant,
    required this.borderFocused,
    required this.borderSelected,
    required this.accent,
    required this.amber,
    required this.green,
    required this.steelBlue,
    required this.lightSteel,
    required this.warmTan,
    required this.mutedGrey,
    required this.punctuationGrey,
    required this.statusSuccess,
    required this.statusRedirect,
    required this.statusClientError,
    required this.statusServerError,
    required this.scrollbarThumb,
    required this.scrollbarThumbHover,
    required this.diffInsert,
    required this.diffInsertBg,
    required this.diffDelete,
    required this.diffDeleteBg,
  });

  static const dark = ColorSet(
    bg: Color(0xFF0C0C0E),
    surface: Color(0xFF161618),
    elevated: Color(0xFF1C1C20),
    hover: Color(0xFF202023),
    active: Color(0xFF2A2A2E),
    text: Color(0xFFE9E9EB),
    textMuted: Color(0xFF8A8A8E),
    textPlaceholder: Color(0xFF515154),
    textDisabled: Color(0xFF515154),
    border: Color(0xFF3A3A3D),
    borderVariant: Color(0xFF232327),
    borderFocused: Color(0xFFE10F1C),
    borderSelected: Color(0xFF6C0D14),
    accent: Color(0xFFE10F1C),
    amber: Color(0xFFD9A441),
    green: Color(0xFF8AB36C),
    steelBlue: Color(0xFF7FA6B8),
    lightSteel: Color(0xFFAEBBCB),
    warmTan: Color(0xFFC9B9A6),
    mutedGrey: Color(0xFF5D636F),
    punctuationGrey: Color(0xFF8A8E96),
    statusSuccess: Color(0xFF8AB36C),
    statusRedirect: Color(0xFF7FA6B8),
    statusClientError: Color(0xFFD9A441),
    statusServerError: Color(0xFFE10F1C),
    scrollbarThumb: Color(0x2EE9E9EB),
    scrollbarThumbHover: Color(0xFF4B4B4D),
    diffInsert: Color(0xFF8AB36C),
    diffInsertBg: Color(0x408AB36C),
    diffDelete: Color(0xFFE10F1C),
    diffDeleteBg: Color(0x40E10F1C),
  );

  static const orangeDark = ColorSet(
    bg: Color(0xFF0C0C0E),
    surface: Color(0xFF161618),
    elevated: Color(0xFF1C1C20),
    hover: Color(0xFF202023),
    active: Color(0xFF2A2A2E),
    text: Color(0xFFE9E9EB),
    textMuted: Color(0xFF8A8A8E),
    textPlaceholder: Color(0xFF515154),
    textDisabled: Color(0xFF515154),
    border: Color(0xFF3A3A3D),
    borderVariant: Color(0xFF232327),
    borderFocused: Color(0xFFFF6A00),
    borderSelected: Color(0xFFCC5500),
    accent: Color(0xFFFF6A00),
    amber: Color(0xFFD9A441),
    green: Color(0xFF8AB36C),
    steelBlue: Color(0xFF7FA6B8),
    lightSteel: Color(0xFFAEBBCB),
    warmTan: Color(0xFFC9B9A6),
    mutedGrey: Color(0xFF5D636F),
    punctuationGrey: Color(0xFF8A8E96),
    statusSuccess: Color(0xFF8AB36C),
    statusRedirect: Color(0xFF7FA6B8),
    statusClientError: Color(0xFFD9A441),
    statusServerError: Color(0xFFFF6A00),
    scrollbarThumb: Color(0x2EE9E9EB),
    scrollbarThumbHover: Color(0xFF4B4B4D),
    diffInsert: Color(0xFF8AB36C),
    diffInsertBg: Color(0x408AB36C),
    diffDelete: Color(0xFFFF6A00),
    diffDeleteBg: Color(0x40FF6A00),
  );

  static const light = ColorSet(
    bg: Color(0xFFFAFAFA),
    surface: Color(0xFFF4F1EA),
    elevated: Color(0xFFFFFFFF),
    hover: Color(0xFFEDEAE2),
    active: Color(0xFFE0DCD4),
    text: Color(0xFF1A1A1C),
    textMuted: Color(0xFF8A8A8E),
    textPlaceholder: Color(0xFFB0B0B4),
    textDisabled: Color(0xFFB0B0B4),
    border: Color(0xFFE0DCD4),
    borderVariant: Color(0xFFD0CCC4),
    borderFocused: Color(0xFFE10F1C),
    borderSelected: Color(0xFF6C0D14),
    accent: Color(0xFFE10F1C),
    amber: Color(0xFFD9A441),
    green: Color(0xFF8AB36C),
    steelBlue: Color(0xFF7FA6B8),
    lightSteel: Color(0xFFAEBBCB),
    warmTan: Color(0xFFC9B9A6),
    mutedGrey: Color(0xFFB0B0B4),
    punctuationGrey: Color(0xFFC0C0C4),
    statusSuccess: Color(0xFF8AB36C),
    statusRedirect: Color(0xFF7FA6B8),
    statusClientError: Color(0xFFD9A441),
    statusServerError: Color(0xFFE10F1C),
    scrollbarThumb: Color(0x2E1A1A1C),
    scrollbarThumbHover: Color(0xFF4B4B4D),
    diffInsert: Color(0xFF8AB36C),
    diffInsertBg: Color(0x408AB36C),
    diffDelete: Color(0xFFE10F1C),
    diffDeleteBg: Color(0x40E10F1C),
  );
}

// ── Syntax themes ──────────────────────────────────────────

Map<String, TextStyle> sootSyntaxTheme(ColorSet colors) => {
  'keyword': TextStyle(color: colors.accent),
  'keyword.type': TextStyle(color: colors.accent),
  'built_in': TextStyle(color: colors.lightSteel),
  'type': TextStyle(color: colors.steelBlue),
  'literal': TextStyle(color: colors.amber),
  'number': TextStyle(color: colors.amber),
  'operator': TextStyle(color: colors.steelBlue),
  'punctuation': TextStyle(color: colors.punctuationGrey),
  'string': TextStyle(color: colors.green),
  'char.escape': TextStyle(color: colors.mutedGrey),
  'subst': TextStyle(color: colors.green),
  'symbol': TextStyle(color: colors.amber),
  'regexp': TextStyle(color: colors.amber),
  'property': TextStyle(color: colors.warmTan),
  'variable': TextStyle(color: colors.text),
  'variable.language': TextStyle(color: colors.accent),
  'variable.constant': TextStyle(color: colors.amber),
  'params': TextStyle(color: colors.text),
  'function': TextStyle(color: colors.lightSteel),
  'title': TextStyle(color: colors.lightSteel),
  'title.function': TextStyle(color: colors.lightSteel),
  'title.class': TextStyle(color: colors.steelBlue),
  'title.class.inherited': TextStyle(color: colors.steelBlue),
  'comment': TextStyle(color: colors.mutedGrey),
  'comment.doc': TextStyle(color: colors.mutedGrey),
  'doctag': TextStyle(color: colors.mutedGrey),
  'meta': TextStyle(color: colors.punctuationGrey),
  'meta.keyword': TextStyle(color: colors.accent),
  'meta.string': TextStyle(color: colors.green),
  'meta.prompt': TextStyle(color: colors.accent),
  'section': TextStyle(color: colors.steelBlue),
  'tag': TextStyle(color: colors.steelBlue),
  'name': TextStyle(color: colors.steelBlue),
  'attr': TextStyle(color: colors.warmTan),
  'attribute': TextStyle(color: colors.warmTan),
  'selector-tag': TextStyle(color: colors.accent),
  'selector-id': TextStyle(color: colors.steelBlue),
  'selector-class': TextStyle(color: colors.amber),
  'selector-attr': TextStyle(color: colors.warmTan),
  'selector-pseudo': TextStyle(color: colors.accent),
  'template-tag': TextStyle(color: colors.accent),
  'template-variable': TextStyle(color: colors.text),
  'addition': TextStyle(color: colors.green),
  'deletion': TextStyle(color: colors.accent),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'link': TextStyle(color: colors.steelBlue),
  'bullet': TextStyle(color: colors.steelBlue),
  'quote': TextStyle(color: colors.green),
  'code': TextStyle(color: colors.green),
  'formula': TextStyle(color: colors.steelBlue),
  'horizontal_rule': TextStyle(color: colors.punctuationGrey),
};

Map<String, TextStyle> sootLightSyntaxTheme(ColorSet colors) => {
  'keyword': TextStyle(color: colors.accent),
  'keyword.type': TextStyle(color: colors.accent),
  'built_in': TextStyle(color: Color(0xFF6B7280)),
  'type': TextStyle(color: Color(0xFF2563EB)),
  'literal': TextStyle(color: Color(0xFF92400E)),
  'number': TextStyle(color: Color(0xFF92400E)),
  'operator': TextStyle(color: Color(0xFF2563EB)),
  'punctuation': TextStyle(color: Color(0xFF6B7280)),
  'string': TextStyle(color: Color(0xFF166534)),
  'char.escape': TextStyle(color: Color(0xFF6B7280)),
  'subst': TextStyle(color: Color(0xFF166534)),
  'symbol': TextStyle(color: Color(0xFF92400E)),
  'regexp': TextStyle(color: Color(0xFF92400E)),
  'property': TextStyle(color: Color(0xFF92400E)),
  'variable': TextStyle(color: Color(0xFF1F2937)),
  'variable.language': TextStyle(color: colors.accent),
  'variable.constant': TextStyle(color: Color(0xFF92400E)),
  'params': TextStyle(color: Color(0xFF1F2937)),
  'function': TextStyle(color: Color(0xFF2563EB)),
  'title': TextStyle(color: Color(0xFF2563EB)),
  'title.function': TextStyle(color: Color(0xFF2563EB)),
  'title.class': TextStyle(color: Color(0xFF2563EB)),
  'title.class.inherited': TextStyle(color: Color(0xFF2563EB)),
  'comment': TextStyle(color: Color(0xFF6B7280)),
  'comment.doc': TextStyle(color: Color(0xFF6B7280)),
  'doctag': TextStyle(color: Color(0xFF6B7280)),
  'meta': TextStyle(color: Color(0xFF6B7280)),
  'meta.keyword': TextStyle(color: colors.accent),
  'meta.string': TextStyle(color: Color(0xFF166534)),
  'meta.prompt': TextStyle(color: colors.accent),
  'section': TextStyle(color: Color(0xFF2563EB)),
  'tag': TextStyle(color: Color(0xFF2563EB)),
  'name': TextStyle(color: Color(0xFF2563EB)),
  'attr': TextStyle(color: Color(0xFF92400E)),
  'attribute': TextStyle(color: Color(0xFF92400E)),
  'selector-tag': TextStyle(color: colors.accent),
  'selector-id': TextStyle(color: Color(0xFF2563EB)),
  'selector-class': TextStyle(color: Color(0xFF92400E)),
  'selector-attr': TextStyle(color: Color(0xFF92400E)),
  'selector-pseudo': TextStyle(color: colors.accent),
  'template-tag': TextStyle(color: colors.accent),
  'template-variable': TextStyle(color: Color(0xFF1F2937)),
  'addition': TextStyle(color: Color(0xFF166534)),
  'deletion': TextStyle(color: colors.accent),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'link': TextStyle(color: Color(0xFF2563EB)),
  'bullet': TextStyle(color: Color(0xFF2563EB)),
  'quote': TextStyle(color: Color(0xFF166534)),
  'code': TextStyle(color: Color(0xFF166534)),
  'formula': TextStyle(color: Color(0xFF2563EB)),
  'horizontal_rule': TextStyle(color: Color(0xFF6B7280)),
};

// ── Dynamic theme builder ──────────────────────────────────

/// Build a [ThemeData] from any [ColorSet].
ThemeData buildAppTheme(ColorSet c) {
  final isDark = c == ColorSet.dark || c == ColorSet.orangeDark;
  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: c.bg,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: c.accent,
            surface: c.surface,
            error: c.accent,
            onPrimary: c.text,
            onSurface: c.text,
            onError: c.text,
          )
        : ColorScheme.light(
            primary: c.accent,
            surface: c.surface,
            error: c.accent,
            onPrimary: Colors.white,
            onSurface: c.text,
            onError: Colors.white,
          ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.elevated,
      foregroundColor: c.text,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: c.text,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    tabBarTheme: TabBarThemeData(
      labelColor: c.text,
      unselectedLabelColor: c.textMuted,
      labelStyle: TextStyle(fontSize: 13),
      unselectedLabelStyle: TextStyle(fontSize: 13),
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.accent, width: 2)),
      ),
      dividerColor: c.border,
      labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.borderFocused),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      hintStyle: TextStyle(color: c.textPlaceholder, fontSize: 13),
      labelStyle: TextStyle(color: c.textMuted, fontSize: 13),
      isDense: true,
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      textColor: c.text,
    ),
    iconTheme: IconThemeData(color: c.textMuted, size: 18),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: c.text, fontSize: 13),
      bodySmall: TextStyle(color: c.textMuted, fontSize: 12),
      titleMedium: TextStyle(color: c.text, fontSize: 14),
      labelSmall: TextStyle(color: c.textMuted, fontSize: 11),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.elevated,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.elevated,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.elevated,
      contentTextStyle: TextStyle(color: c.text),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent
            : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(c.text),
      side: BorderSide(color: c.border),
    ),
  );
}

/// Back-compat alias for tests and legacy references.
final ThemeData appTheme = buildAppTheme(ColorSet.dark);
