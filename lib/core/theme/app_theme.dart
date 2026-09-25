import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  AppTheme._();

  // Core Colors - The Digital Curator Palette
  static const Color obsidianBase = Color(0xFF131313);
  static const Color obsidianLayer1 = Color(0xFF1C1B1B);
  static const Color obsidianLayer2 = Color(0xFF201F1F);
  static const Color obsidianLayer3 = Color(0xFF353534);
  
  static const Color electricTeal = Color(0xFF008080);
  static const Color vibrantTeal = Color(0xFF76D6D5);
  static const Color accentPeach = Color(0xFFE9967A);
  static const Color softGrey = Color(0xFFE5E2E1);

  static ThemeData get darkTheme => _buildTheme();

  static ThemeData _buildTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: electricTeal,
      brightness: Brightness.dark,
      surface: obsidianBase,
      onSurface: softGrey,
      primary: electricTeal,
      secondary: vibrantTeal,
      tertiary: accentPeach,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: obsidianBase,
      
      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          color: softGrey,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.inter(
          color: softGrey,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        labelMedium: GoogleFonts.inter(
          color: softGrey.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
        bodyLarge: const TextStyle(color: Colors.white),
        bodyMedium: const TextStyle(color: softGrey),
        titleMedium: const TextStyle(color: Colors.white),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: softGrey,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: softGrey),
      ),

      cardTheme: CardThemeData(
        color: obsidianLayer2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: obsidianLayer1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricTeal, width: 1.5),
        ),
        labelStyle: const TextStyle(color: softGrey),
        hintStyle: TextStyle(color: softGrey.withValues(alpha: 0.3), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: vibrantTeal),
        prefixIconColor: softGrey.withValues(alpha: 0.5),
        suffixIconColor: softGrey.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
