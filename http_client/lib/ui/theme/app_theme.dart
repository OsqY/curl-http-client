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

/// Soot dark theme — monochrome-dominant.

/// Soot syntax highlighting theme.
final Map<String, TextStyle> sootSyntaxTheme = {
  'keyword': TextStyle(color: AppColors.accent),
  'keyword.type': TextStyle(color: AppColors.accent),
  'built_in': TextStyle(color: AppColors.lightSteel),
  'type': TextStyle(color: AppColors.steelBlue),
  'literal': TextStyle(color: AppColors.amber),
  'number': TextStyle(color: AppColors.amber),
  'operator': TextStyle(color: AppColors.steelBlue),
  'punctuation': TextStyle(color: AppColors.punctuationGrey),
  'string': TextStyle(color: AppColors.green),
  'char.escape': TextStyle(color: AppColors.mutedGrey),
  'subst': TextStyle(color: AppColors.green),
  'symbol': TextStyle(color: AppColors.amber),
  'regexp': TextStyle(color: AppColors.amber),
  'property': TextStyle(color: AppColors.warmTan),
  'variable': TextStyle(color: AppColors.text),
  'variable.language': TextStyle(color: AppColors.accent),
  'variable.constant': TextStyle(color: AppColors.amber),
  'params': TextStyle(color: AppColors.text),
  'function': TextStyle(color: AppColors.lightSteel),
  'title': TextStyle(color: AppColors.lightSteel),
  'title.function': TextStyle(color: AppColors.lightSteel),
  'title.class': TextStyle(color: AppColors.steelBlue),
  'title.class.inherited': TextStyle(color: AppColors.steelBlue),
  'comment': TextStyle(color: AppColors.mutedGrey),
  'comment.doc': TextStyle(color: AppColors.mutedGrey),
  'doctag': TextStyle(color: AppColors.mutedGrey),
  'meta': TextStyle(color: AppColors.punctuationGrey),
  'meta.keyword': TextStyle(color: AppColors.accent),
  'meta.string': TextStyle(color: AppColors.green),
  'meta.prompt': TextStyle(color: AppColors.accent),
  'section': TextStyle(color: AppColors.steelBlue),
  'tag': TextStyle(color: AppColors.steelBlue),
  'name': TextStyle(color: AppColors.steelBlue),
  'attr': TextStyle(color: AppColors.warmTan),
  'attribute': TextStyle(color: AppColors.warmTan),
  'selector-tag': TextStyle(color: AppColors.accent),
  'selector-id': TextStyle(color: AppColors.steelBlue),
  'selector-class': TextStyle(color: AppColors.amber),
  'selector-attr': TextStyle(color: AppColors.warmTan),
  'selector-pseudo': TextStyle(color: AppColors.accent),
  'template-tag': TextStyle(color: AppColors.accent),
  'template-variable': TextStyle(color: AppColors.text),
  'addition': TextStyle(color: AppColors.green),
  'deletion': TextStyle(color: AppColors.accent),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'link': TextStyle(color: AppColors.steelBlue),
  'bullet': TextStyle(color: AppColors.steelBlue),
  'quote': TextStyle(color: AppColors.green),
  'code': TextStyle(color: AppColors.green),
  'formula': TextStyle(color: AppColors.steelBlue),
  'horizontal_rule': TextStyle(color: AppColors.punctuationGrey),
};

/// Soot dark theme — monochrome-dominant.
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  visualDensity: VisualDensity.compact,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.accent,
    onPrimary: AppColors.text,
    onSurface: AppColors.text,
    onError: AppColors.text,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.elevated,
    foregroundColor: AppColors.text,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: AppColors.text,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: AppColors.text,
    unselectedLabelColor: AppColors.textMuted,
    labelStyle: TextStyle(fontSize: 13),
    unselectedLabelStyle: TextStyle(fontSize: 13),
    indicator: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.accent, width: 2)),
    ),
    dividerColor: AppColors.border,
    labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.borderFocused),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
    labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
    isDense: true,
  ),
  listTileTheme: const ListTileThemeData(
    dense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    textColor: AppColors.text,
  ),
  iconTheme: const IconThemeData(color: AppColors.textMuted, size: 18),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
    titleMedium: TextStyle(color: AppColors.text, fontSize: 14),
    labelSmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.elevated,
    surfaceTintColor: Colors.transparent,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColors.elevated,
    surfaceTintColor: Colors.transparent,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: AppColors.elevated,
    contentTextStyle: TextStyle(color: AppColors.text),
  ),
);
