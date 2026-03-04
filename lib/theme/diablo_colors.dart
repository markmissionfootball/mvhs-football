import 'package:flutter/material.dart';

class DiabloColors {
  DiabloColors._();

  static const Color red = Color(0xFFD12132);
  static const Color gold = Color(0xFFFCB423);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color maroon = Color(0xFF8B0000);
  static const Color background = Color(0xFFE8E4DE);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color white = Colors.white;
  static const Color cardSurface = Colors.white;

  // Dark mode variants
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFE5E5E5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Stat card gradients
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, maroon, red],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, Color(0xFFE8A520), gold],
  );
}
