import 'package:flutter/material.dart';

class AppTheme {
  // --- Colors ---
  static const Color _primaryBlue = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F7FB);
  static const Color _darkBg = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF2C2C2C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryBlue,
        brightness: Brightness.light,
        primary: _primaryBlue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF1D1A20),
        surfaceContainerHighest: const Color(0xFFEEF2FF),
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBg,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1D1A20), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFF1D1A20), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFF1D1A20), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFF1D1A20), fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Color(0xFF1D1A20), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFF1D1A20)),
        bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
        bodySmall: TextStyle(color: Color(0xFF6D6D6D)),
        labelSmall: TextStyle(color: Color(0xFF6D6D6D)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          side: const BorderSide(color: _primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: _primaryBlue,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6D6D6D), fontFamily: 'Cairo'),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'Cairo'),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryBlue,
        brightness: Brightness.dark,
        primary: const Color(0xFF90CAF9),
        onPrimary: Colors.black,
        surface: _darkSurface,
        onSurface: const Color(0xFFE6E1E5),
        surfaceContainerHighest: _darkCard,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: _darkBg,
      cardColor: _darkCard,
      dividerColor: Colors.grey.shade800,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFFE6E1E5), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFE6E1E5), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFFE6E1E5), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFFE6E1E5), fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Color(0xFFE6E1E5), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFFCAC4D0)),
        bodyMedium: TextStyle(color: Color(0xFFCAC4D0)),
        bodySmall: TextStyle(color: Color(0xFF938F99)),
        labelSmall: TextStyle(color: Color(0xFF938F99)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF90CAF9),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          side: const BorderSide(color: Color(0xFF90CAF9)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkCard,
        selectedColor: const Color(0xFF1565C0),
        labelStyle: const TextStyle(fontFamily: 'Cairo', color: Color(0xFFE6E1E5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF938F99), fontFamily: 'Cairo'),
        hintStyle: const TextStyle(color: Color(0xFF938F99), fontFamily: 'Cairo'),
      ),
    );
  }
}
