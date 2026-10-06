import 'package:flutter/material.dart';

/// Desert Theme Color Palette (Light & Dark)
/// Material 3 compliant with high contrast (WCAG AA)
class AppColors {
  // --- Light Desert Palette ---
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

  // --- Markup Inking Color Presets (Strictly Preserved) ---
  static const Color inkRed = Color(0xFFC0452A);
  static const Color inkBlue = Color(0xFF185FA5);
  static const Color inkDark = Color(0xFF2C2C2A);
  static const Color inkOrange = Color(0xFFE08A5B);

  // --- Paper Canvas Color (Stays pure white in BOTH modes) ---
  static const Color canvasPaper = Color(0xFFFFFFFF);
}

const List<Color> kDesertMarkupColors = [
  AppColors.inkRed,
  AppColors.inkBlue,
  AppColors.inkDark,
  AppColors.inkOrange,
];
