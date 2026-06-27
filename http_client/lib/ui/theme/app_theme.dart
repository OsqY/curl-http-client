import 'package:flutter/material.dart';

/// Insomnia-style dark color palette.
class AppColors {
  AppColors._();

  // Background
  static const bgDefault = Color(0xFF2C2C2C);
  static const bgSuccess = Color(0xFF7ECF2B);
  static const bgNotice = Color(0xFFF0E137);
  static const bgWarning = Color(0xFFFF9A1F);
  static const bgDanger = Color(0xFFFF5631);
  static const bgSurprise = Color(0xFFA896FF);
  static const bgInfo = Color(0xFF46C1E6);

  // Foreground
  static const fgDefault = Color(0xFFDDDDDD);
  static const fgMuted = Color(0xFF999999);

  // Sidebar
  static const sidebarBg = Color(0xFF2C2C2C);
  static const sidebarFg = Color(0xFFE0E0E0);
  static const sidebarHeaderBg = Color(0xFF695EB8);

  // Pane
  static const paneBg = Color(0xFF292929);
  static const paneFg = Color(0xFFE0E0E0);
  static const paneHeaderBg = Color(0xFF212121);
  static const paneHeaderFg = Color(0xFFCCCCCC);

  // Dialog
  static const dialogBg = Color(0xFF2A2A2A);

  // Borders
  static const border = Color(0xFF3A3A3A);
  static const borderLight = Color(0xFF444444);
}

/// Insomnia-style dark theme.
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  visualDensity: VisualDensity.compact,
  scaffoldBackgroundColor: AppColors.paneBg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.sidebarHeaderBg,
    surface: AppColors.paneBg,
    error: AppColors.bgDanger,
    onPrimary: Colors.white,
    onSurface: AppColors.paneFg,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.sidebarHeaderBg,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: AppColors.fgDefault,
    unselectedLabelColor: AppColors.fgMuted,
    labelStyle: TextStyle(fontSize: 13),
    unselectedLabelStyle: TextStyle(fontSize: 13),
    indicator: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppColors.sidebarHeaderBg, width: 2),
      ),
    ),
    dividerColor: AppColors.border,
    labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: AppColors.paneHeaderBg,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.sidebarHeaderBg),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    hintStyle: TextStyle(color: AppColors.fgMuted, fontSize: 13),
    labelStyle: TextStyle(color: AppColors.fgMuted, fontSize: 13),
    isDense: true,
  ),
  listTileTheme: const ListTileThemeData(
    dense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    textColor: AppColors.sidebarFg,
  ),
  iconTheme: const IconThemeData(
    color: AppColors.fgMuted,
    size: 18,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: AppColors.fgDefault, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.fgMuted, fontSize: 12),
    titleMedium: TextStyle(color: AppColors.fgDefault, fontSize: 14),
    labelSmall: TextStyle(color: AppColors.fgMuted, fontSize: 11),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.dialogBg,
    surfaceTintColor: Colors.transparent,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColors.dialogBg,
    surfaceTintColor: Colors.transparent,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: AppColors.paneHeaderBg,
    contentTextStyle: TextStyle(color: AppColors.fgDefault),
  ),
);
