import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors dari Figma Museum Brawijaya
  static const Color primaryGreen = Color(0xFF2D4A22);
  static const Color darkGreen = Color(0xFF1A2E14);
  static const Color lightGreen = Color(0xFF4A7A35);
  static const Color creamBg = Color(0xFFF5F0E8);
  static const Color warmWhite = Color(0xFFFAF7F2);
  static const Color goldAccent = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFD4A853);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B6B6B);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color dividerColor = Color(0xFFE0D8CC);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: creamBg,
      textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: textDark),
        bodyMedium: GoogleFonts.lato(fontSize: 14, color: textDark),
        bodySmall: GoogleFonts.lato(fontSize: 12, color: textGrey),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.lato(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.lato(color: textGrey, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: warmWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: warmWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
