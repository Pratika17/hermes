import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel Color Palette
  static const Color primaryTeal = Color(0xFFA0EACD); // Soft Teal
  static const Color accentPink = Color(0xFFFFD1DC); // Pastel Pink
  static const Color backgroundLight = Color(
    0xFFF0F4F8,
  ); // Very light grey/blue
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFF636E72);

  // Subject Colors (for Timetable)
  static const List<Color> subjectColors = [
    Color(0xFFE2F0CB), // Pastel Green
    Color(0xFFFFE5D9), // Pastel Peach
    Color(0xFFFFCAD4), // Pastel Pink
    Color(0xFFC7CEEA), // Pastel Purple
    Color(0xFFB5EAD7), // Mint
    Color(0xFFFFF7AC), // Pastel Yellow
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryTeal,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: Color(0xFF00B894), // Darker teal for interaction
      secondary: accentPink,
      surface: cardColor,
      background: backgroundLight,
    ),
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: textDark,
      displayColor: textDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00B894),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
