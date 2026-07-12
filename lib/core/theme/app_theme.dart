import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primary = Color(0xFF1A6B3C);
  static const accent = Color(0xFF2E9E5B);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const background = Color(0xFFF8FAF9);
  static const surface = Colors.white;
  static const divider = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}
