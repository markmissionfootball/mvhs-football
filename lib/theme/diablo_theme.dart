import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'diablo_colors.dart';

class DiabloTheme {
  DiabloTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: DiabloColors.red,
      scaffoldBackgroundColor: DiabloColors.background,
      colorScheme: const ColorScheme.light(
        primary: DiabloColors.red,
        secondary: DiabloColors.gold,
        surface: DiabloColors.cardSurface,
        onPrimary: DiabloColors.white,
        onSecondary: DiabloColors.red,
        onSurface: DiabloColors.textPrimary,
      ),
      textTheme: _buildTextTheme(DiabloColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: DiabloColors.red,
        foregroundColor: DiabloColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DiabloColors.dark,
        selectedItemColor: DiabloColors.gold,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DiabloColors.gold,
          foregroundColor: DiabloColors.red,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DiabloColors.white,
          side: const BorderSide(color: DiabloColors.white),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DiabloColors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: DiabloColors.cardSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDDDDD),
        thickness: 1,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: DiabloColors.red,
      scaffoldBackgroundColor: DiabloColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: DiabloColors.red,
        secondary: DiabloColors.gold,
        surface: DiabloColors.darkSurface,
        onPrimary: DiabloColors.white,
        onSecondary: DiabloColors.red,
        onSurface: DiabloColors.darkTextPrimary,
      ),
      textTheme: _buildTextTheme(DiabloColors.darkTextPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: DiabloColors.red,
        foregroundColor: DiabloColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DiabloColors.dark,
        selectedItemColor: DiabloColors.gold,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DiabloColors.gold,
          foregroundColor: DiabloColors.red,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DiabloColors.white,
          side: const BorderSide(color: DiabloColors.white),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DiabloColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DiabloColors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: DiabloColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return GoogleFonts.openSansTextTheme(
      TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 2.0,
          color: baseColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
          color: baseColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.2,
          color: baseColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: baseColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: baseColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: baseColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: baseColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: baseColor.withValues(alpha: 0.7),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: baseColor,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: baseColor,
        ),
      ),
    );
  }
}
