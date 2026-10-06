import 'package:flutter/material.dart';

/// Desert & Outdoor Theme Color Palette (Light, Dark, and Outdoor Sunlight)
/// Material 3 compliant with WCAG AAA (7:1) high contrast direct sunlight mode
class AppColors {
  // --- Light Desert Palette (Standard) ---
  static const Color lightBackground = Color(0xFFF6EDE0);
  static const Color lightSurface = Color(0xFFFFFBF4);
  static const Color lightPrimary = Color(0xFFB85A32); // Terracotta
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF3B2A1E);
  static const Color lightSecondaryText = Color(0xFF8A7461);
  static const Color lightOutline = Color(0xFFE4D3BC);
  static const Color lightChip = Color(0xFFF0E0C6);
  static const Color lightAccent = Color(0xFFE8C48A);

  // --- Dark Desert Palette ---
  static const Color darkBackground = Color(0xFF1C1511);
  static const Color darkSurface = Color(0xFF2A201A);
  static const Color darkPrimary = Color(0xFFE08A5B); // Warm Terracotta
  static const Color darkOnPrimary = Color(0xFF2A1408);
  static const Color darkText = Color(0xFFF3E6D3);
  static const Color darkSecondaryText = Color(0xFFB9A48C);
  static const Color darkOutline = Color(0xFF40322A);
  static const Color darkChip = Color(0xFF35281F);
  static const Color darkAccent = Color(0xFF8A6A35);

  // --- Outdoor Palette (Direct Sunlight High-Contrast WCAG AAA) ---
  static const Color outdoorBackground = Color(0xFFFFFFFF);
  static const Color outdoorSurface = Color(0xFFFFFFFF);
  static const Color outdoorText = Color(0xFF0B1417);          // 18.6:1 contrast on #FFFFFF (WCAG AAA)
  static const Color outdoorSecondaryText = Color(0xFF3F4D52); // 8.9:1 contrast on #FFFFFF (WCAG AAA)
  static const Color outdoorPrimary = Color(0xFF08605B);       // Deep Teal (6.8:1 contrast on #FFFFFF)
  static const Color outdoorOnPrimary = Color(0xFFFFFFFF);
  static const Color outdoorOutline = Color(0xFF5F6F75);       // 1.5px high-visibility border
  static const Color outdoorChip = Color(0xFFE3E8EA);

  // --- Standard 7 Preset Dots (Standard / Dark Mode) ---
  static const Color inkRed = Color(0xFFD03A33);       // Revision / Modify
  static const Color inkBlue = Color(0xFF185FA5);      // Check / Verify
  static const Color inkGreen = Color(0xFF2E8B3E);     // Dimension / Measurement
  static const Color inkOrange = Color(0xFFEF9F27);    // Add / New
  static const Color inkYellow = Color(0xFFF2D13A);
  static const Color inkPurple = Color(0xFF7A3FB5);
  static const Color inkDark = Color(0xFF2C2C2A);

  // --- Outdoor High-Contrast Markup Presets (Strictly No Yellow, No Pastels) ---
  static const Color outdoorInkRed = Color(0xFFC62828);
  static const Color outdoorInkBlue = Color(0xFF185FA5);
  static const Color outdoorInkGreen = Color(0xFF1F6B2D);
  static const Color outdoorInkDark = Color(0xFF111111);
  static const Color outdoorInkOrange = Color(0xFFC25E00);

  // --- Paper Canvas Color (Stays pure white in ALL themes) ---
  static const Color canvasPaper = Color(0xFFFFFFFF);
}

// 7 Preset colors for Standard / Dark mode
const List<Color> kReferenceColorPresets = [
  AppColors.inkRed,
  AppColors.inkBlue,
  AppColors.inkGreen,
  AppColors.inkOrange,
  AppColors.inkYellow,
  AppColors.inkPurple,
  AppColors.inkDark,
];

// 5 High-Contrast Presets for Outdoor Sunlight mode (No yellow)
const List<Color> kOutdoorColorPresets = [
  AppColors.outdoorInkRed,
  AppColors.outdoorInkBlue,
  AppColors.outdoorInkGreen,
  AppColors.outdoorInkDark,
  AppColors.outdoorInkOrange,
];

// Backward-compatibility aliases
const List<Color> kMarkupColorPresets = kReferenceColorPresets;
const List<Color> kDesertMarkupColors = kReferenceColorPresets;
