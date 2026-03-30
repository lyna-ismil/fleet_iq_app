import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color brandBlue = Color(0xFF0A66FF);
  static const Color brandLight = Color(0xFFEAF2FF);
  static const Color textMain = Color(0xFF1A1B1E);
  static const Color textMuted = Color(0xFF8A8D93);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF5F6F8);
  static const Color surfaceBorder = Color(0xFFE5E7EB);
  
  // Accents
  static const Color starRating = Color(0xFFFFB300);
  static const Color mapRoute = Color(0xFFFF8C00);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFDC2626);

  // Border Radii
  static const double radiusButton = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: brandBlue,
      scaffoldBackgroundColor: surfaceWhite,
      colorScheme: const ColorScheme.light(
        primary: brandBlue,
        secondary: brandLight,
        surface: surfaceWhite,
        error: Colors.redAccent,
        onPrimary: surfaceWhite,
        onSecondary: brandBlue,
        onSurface: textMain,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textMain,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: textMain,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            color: textMain,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: textMain,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(
            color: textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: surfaceWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: surfaceWhite,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          side: const BorderSide(color: surfaceBorder, width: 1),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        shadowColor: Colors.black.withOpacity(0.06),
        elevation: 8,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: brandBlue,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Common box shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
      
  static List<BoxShadow> get subtleShadow => softShadow;
}
