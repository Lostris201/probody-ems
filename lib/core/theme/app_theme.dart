import 'package:flutter/material.dart';

class AppTheme {
  // Primary color for the app - corresponds to Probody blue
  static const Color primaryColor = Color(0xFF005EEF);
  static const Color secondaryColor = Color(0xFF6B42A8);
  static const Color accentColor = Color(0xFF00A3FF);
  
  // Text and background colors
  static const Color textDarkColor = Color(0xFF333333);
  static const Color textLightColor = Color(0xFFFFFFFF);
  static const Color backgroundLightColor = Color(0xFFF5F7FA);
  static const Color backgroundDarkColor = Color(0xFF2D2D2D);
  
  // Success, Warning, Error colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  
  // Card and divider colors
  static const Color cardLightColor = Color(0xFFFFFFFF);
  static const Color cardDarkColor = Color(0xFF3D3D3D);
  static const Color dividerLightColor = Color(0xFFE0E0E0);
  static const Color dividerDarkColor = Color(0xFF424242);

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onPrimary: textLightColor,
      onSecondary: textLightColor,
      surface: cardLightColor,
      background: backgroundLightColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundLightColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: textLightColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: cardLightColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: textLightColor,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        borderSide: const BorderSide(color: dividerLightColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerLightColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textDarkColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textDarkColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textDarkColor, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textDarkColor),
      bodyMedium: TextStyle(color: textDarkColor),
      bodySmall: TextStyle(color: Colors.grey[700]),
      labelLarge: TextStyle(color: textDarkColor, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: textDarkColor),
      labelSmall: TextStyle(color: Colors.grey[700]),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      onPrimary: textLightColor,
      onSecondary: textLightColor,
      surface: cardDarkColor,
      background: backgroundDarkColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundDarkColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDarkColor,
      foregroundColor: textLightColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: cardDarkColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: textLightColor,
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: const BorderSide(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDarkColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerDarkColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerDarkColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerDarkColor,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textLightColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textLightColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textLightColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textLightColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textLightColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: textLightColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textLightColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textLightColor, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textLightColor, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textLightColor),
      bodyMedium: TextStyle(color: textLightColor),
      bodySmall: TextStyle(color: Colors.grey[400]),
      labelLarge: TextStyle(color: textLightColor, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: textLightColor),
      labelSmall: TextStyle(color: Colors.grey[400]),
    ),
  );
}