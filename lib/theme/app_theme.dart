import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF005587);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFE0E0E0);

  // Coverage Colors
  static const Color coverageNone = Color(0xFF9E9E9E);
  static const Color coverageLow = Color(0xFFFFC107);
  static const Color coverageMedium = Color(0xFFFF9800);
  static const Color coverageHigh = Color(0xFF4CAF50);
  static const Color coverageBlocked = Color(0xFF2196F3);

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        displayMedium: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        displaySmall: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2, // approximating 0px 2px 4px rgba(0,0,0,0.05)
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 2,
        shadowColor: Colors.black12,
        centerTitle: false,
      ),
    );
  }
}
