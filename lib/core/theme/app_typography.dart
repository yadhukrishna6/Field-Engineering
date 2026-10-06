import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uniform Engineering Typography System
/// Strictly standardizes all field notes, text markups, dimensions, and callouts
/// in a single bundled technical CAD font (ISOCPEUR / Monospace DIN standard).
class AppTypography {
  /// Bundled standard engineering font family identifier
  static const String engineeringFontFamily = 'EngineeringFont';

  /// Standard engineering text style for CAD drawings, P&ID markups, and field notes.
  /// Standardized across all tablets for client review consistency.
  static TextStyle engineeringTextStyle({
    double fontSize = 13.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 0.5,
    double height = 1.2,
    Shadows? shadows,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: engineeringFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    }

    try {
      return GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    } catch (_) {
      // Offline fallback to bundled engineering font
      return TextStyle(
        fontFamily: engineeringFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    }
  }

  /// Preset font sizes for engineering notes
  static const double fontSizeSmall = 11.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeHeader = 20.0;
  static const double fontSizeTitle = 24.0;
}

typedef Shadows = List<Shadow>;
