import 'package:flutter/material.dart';

class AppColors {
  // Industrial Engineering Primary Colors
  static const Color primary = Color(0xFF0F52BA); // Industrial Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF0A3678);

  // Field Safety & High-Vis Accents
  static const Color safetyOrange = Color(0xFFFF6B00); // Safety Orange
  static const Color safetyOrangeLight = Color(0xFFFF8C38);
  static const Color industrialYellow = Color(0xFFFBBF24); // Caution Yellow

  // Status Indicators
  static const Color online = Color(0xFF10B981); // Emerald Green
  static const Color offline = Color(0xFFF59E0B); // Desert Amber
  static const Color syncPending = Color(0xFF0EA5E9); // Electric Cyan
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusOnHold = Color(0xFFF59E0B);
  static const Color statusCompleted = Color(0xFF6366F1);
  static const Color statusArchived = Color(0xFF64748B);

  // Dark Theme Palette (Rugged Field Charcoal)
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF131D31);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1A263D);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette (High-Contrast Sunlight / Outdoor Mode)
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE2E8F0);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Drawing Type Category Badges
  static const Color drawingPid = Color(0xFF0284C7); // Process & Instrumentation (Sky Blue)
  static const Color drawingIsometric = Color(0xFF7C3AED); // Piping Isometric (Purple)
  static const Color drawingElectrical = Color(0xFFD97706); // Electrical / SLD (Amber)
  static const Color drawingMechanical = Color(0xFF059669); // Mechanical / Equipment (Green)
  static const Color drawingStructural = Color(0xFFDC2626); // Structural / Steel (Red)
  static const Color drawingCivil = Color(0xFF4B5563); // Civil / Earthworks (Slate)
  static const Color drawingPiping = Color(0xFF4338CA); // Piping General (Indigo)
  static const Color drawingGeneral = Color(0xFF0D9488); // General Arrangement (Teal)
}

class DrawingColorItem {
  final String name;
  final Color color;
  const DrawingColorItem(this.name, this.color);
}

class DrawingColorPalette {
  static const List<DrawingColorItem> engineeringPalette = [
    DrawingColorItem('Safety Red', Color(0xFFD32F2F)),
    DrawingColorItem('Field Green', Color(0xFF2E7D32)),
    DrawingColorItem('Process Blue', Color(0xFF1565C0)),
    DrawingColorItem('Dimension Cyan', Color(0xFF0288D1)),
    DrawingColorItem('Warning Yellow', Color(0xFFFBC02D)),
    DrawingColorItem('Instrument Purple', Color(0xFF7B1FA2)),
    DrawingColorItem('Hazard Orange', Color(0xFFFF6F00)),
    DrawingColorItem('Carbon Black', Color(0xFF212121)),
    DrawingColorItem('Pure White', Color(0xFFFFFFFF)),
  ];
}
