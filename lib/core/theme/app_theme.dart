import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const pretendard = 'Pretendard';
  static const gowunDodum = 'GowunDodum';
  static const notoSansKr = 'NotoSansKR';
  static const primary = Color(0xFF123C3B);
  static const accent = Color(0xFF0E9F8B);
  static const coral = Color(0xFFFF7656);
  static const warning = Color(0xFFF3A43B);
  static const success = Color(0xFF0E9F8B);
  static const background = Color(0xFFF7F7F3);
  static const surface = Colors.white;
  static const softMint = Color(0xFFDDF1E9);
  static const softCoral = Color(0xFFFFECE6);
  static const divider = Color(0xFFE7E9E4);
  static const textPrimary = Color(0xFF152321);
  static const textSecondary = Color(0xFF71807D);

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: pretendard,
      fontFamilyFallback: const [notoSansKr],
      dividerColor: divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static const displayStyle = TextStyle(
    fontFamily: gowunDodum,
    fontWeight: FontWeight.w400,
  );
}
