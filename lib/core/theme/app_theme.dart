import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// ثيم وتنسيقات تطبيق إدارة مكتب المحاماة السوري (دعم RTL الكامل وخط Cairo / Amiri)
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppConstants.defaultPrintFont, // Cairo كخط أساسي
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryNavy,
      scaffoldBackgroundColor: AppConstants.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryNavy,
        primary: AppConstants.primaryNavy,
        secondary: AppConstants.accentGold,
        surface: AppConstants.surfaceWhite,
        error: AppConstants.statusDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: AppConstants.surfaceWhite,
        centerTitle: true,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontFamily: AppConstants.defaultPrintFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.surfaceWhite,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.surfaceWhite,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryNavy,
          foregroundColor: AppConstants.surfaceWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: AppConstants.defaultPrintFont,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryNavy,
          side: const BorderSide(color: AppConstants.primaryNavy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: AppConstants.defaultPrintFont,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCED4DA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCED4DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConstants.accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConstants.statusDanger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.accentGold,
        foregroundColor: AppConstants.primaryNavy,
        elevation: 4,
      ),
    );
  }
}
