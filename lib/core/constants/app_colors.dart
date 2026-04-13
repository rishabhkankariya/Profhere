import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary     = Color(0xFF4F46E5); // indigo-600
  static const Color primaryLight= Color(0xFFEEF2FF); // indigo-50
  static const Color primaryDark = Color(0xFF3730A3); // indigo-800
  static const Color secondary   = Color(0xFF0EA5E9); // sky-500

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successBg  = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg  = Color(0xFFFFFBEB);
  static const Color error   = Color(0xFFDC2626);
  static const Color errorBg    = Color(0xFFFEF2F2);
  static const Color info    = Color(0xFF0284C7);
  static const Color infoBg     = Color(0xFFF0F9FF);

  // Faculty Status
  static const Color available    = Color(0xFF16A34A);
  static const Color busy         = Color(0xFFD97706);
  static const Color inLecture    = Color(0xFFDC2626);
  static const Color away         = Color(0xFF6B7280);
  static const Color meeting      = Color(0xFF7C3AED);
  static const Color notAvailable = Color(0xFF374151);

  // Surfaces (light)
  static const Color background      = Color(0xFFF8FAFC);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color surfaceHigh     = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textDisabled  = Color(0xFFCBD5E1);

  // Border
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF4F46E5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Scaffold backgrounds (used across hub / list screens).
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Accent brand (headers, chips); matches [secondary] hue.
  static const Color accent = Color(0xFF0EA5E9);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
