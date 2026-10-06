import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // --- 1. Standard Desert Light Theme ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightAccent,
        onSecondary: AppColors.lightText,
        error: Colors.redAccent,
        onError: Colors.white,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightText,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        outline: AppColors.lightOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightOutline, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightChip,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lightText),
      ),
    );
  }

  // --- 2. Desert Dark Theme ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkAccent,
        onSecondary: AppColors.darkText,
        error: Colors.redAccent,
        onError: Colors.white,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkText,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        outline: AppColors.darkOutline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkOutline, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkChip,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkText),
      ),
    );
  }

  // --- 3. Outdoor High-Contrast Sunlight Theme (WCAG AAA) ---
  static ThemeData get outdoorTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.outdoorBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.outdoorPrimary,
        onPrimary: AppColors.outdoorOnPrimary,
        secondary: AppColors.outdoorPrimary,
        onSecondary: AppColors.outdoorOnPrimary,
        error: Color(0xFFC62828),
        onError: Colors.white,
        background: AppColors.outdoorBackground,
        onBackground: AppColors.outdoorText,
        surface: AppColors.outdoorSurface,
        onSurface: AppColors.outdoorText,
        outline: AppColors.outdoorOutline,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.outdoorText),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.outdoorText),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.outdoorText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.outdoorText),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.outdoorSecondaryText),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.outdoorSecondaryText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.outdoorBackground,
        foregroundColor: AppColors.outdoorText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.outdoorText,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.outdoorText, size: 24),
      ),
      cardTheme: CardTheme(
        color: AppColors.outdoorSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outdoorOutline, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.outdoorPrimary,
          foregroundColor: AppColors.outdoorOnPrimary,
          minimumSize: const Size(48, 48), // Min 48dp touch target
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.outdoorOutline, width: 1.5),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.outdoorPrimary,
          minimumSize: const Size(48, 48), // Min 48dp touch target
          side: const BorderSide(color: AppColors.outdoorOutline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.outdoorChip,
        side: const BorderSide(color: AppColors.outdoorOutline, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.outdoorText),
      ),
    );
  }
}
