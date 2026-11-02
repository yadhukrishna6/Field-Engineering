import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available downloaded engineering and handwriting fonts
enum EngineeringFont {
  architectural(
    id: 'architectural',
    displayName: 'Architectural Hand',
    subtitle: 'Classic Blueprint Pen Lettering',
    samplePreview: 'SL6 • 4"-HC-1002',
  ),
  caveat(
    id: 'caveat',
    displayName: 'Natural Pen Script',
    subtitle: 'Organic Fluid Handwriting',
    samplePreview: 'SL6 • Verified on site',
  ),
  patrickHand(
    id: 'patrickHand',
    displayName: 'Technical Drafting',
    subtitle: 'Clean Hand-Lettered Drafting (ASME)',
    samplePreview: 'SL6 • ELEV +12.450',
  ),
  kalam(
    id: 'kalam',
    displayName: 'Blueprint Marker',
    subtitle: 'Bold Field Marker Script',
    samplePreview: 'SL6 • HOLD FOR REVIEW',
  ),
  cadMonospace(
    id: 'cadMonospace',
    displayName: 'CAD Monospace DIN',
    subtitle: 'Standard DIN / ISO 3098 Drafting',
    samplePreview: 'SL6 • ISO-4500-DESERT',
  ),
  modernSans(
    id: 'modernSans',
    displayName: 'Modern Technical Sans',
    subtitle: 'High-Legibility Precision Sans',
    samplePreview: 'SL6 • Specification 02A',
  );

  final String id;
  final String displayName;
  final String subtitle;
  final String samplePreview;

  const EngineeringFont({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.samplePreview,
  });

  static EngineeringFont fromId(String? id) {
    if (id == null) return EngineeringFont.architectural;
    return EngineeringFont.values.firstWhere(
      (f) => f.id == id || f.name == id || f.displayName == id,
      orElse: () => EngineeringFont.architectural,
    );
  }
}

/// Uniform Engineering Typography System
/// Supports multiple downloaded fonts (handwriting, architectural, CAD)
class AppTypography {
  /// Bundled fallback engineering font family identifier
  static const String engineeringFontFamily = 'EngineeringFont';

  /// Returns text style formatted in the chosen downloaded font
  static TextStyle getTextStyle({
    EngineeringFont font = EngineeringFont.architectural,
    double fontSize = 13.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 0.5,
    double height = 1.2,
    Shadows? shadows,
  }) {
    try {
      switch (font) {
        case EngineeringFont.architectural:
          return GoogleFonts.architectsDaughter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
        case EngineeringFont.caveat:
          return GoogleFonts.caveat(
            fontSize: fontSize + 2.0,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
        case EngineeringFont.patrickHand:
          return GoogleFonts.patrickHand(
            fontSize: fontSize + 1.0,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
        case EngineeringFont.kalam:
          return GoogleFonts.kalam(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
        case EngineeringFont.modernSans:
          return GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
        case EngineeringFont.cadMonospace:
          return GoogleFonts.jetBrainsMono(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            height: height,
            shadows: shadows,
          );
      }
    } catch (_) {
      return TextStyle(
        fontFamily: font.id,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      );
    }
  }

  /// Standard engineering text style for CAD drawings, P&ID markups, and field notes.
  static TextStyle engineeringTextStyle({
    EngineeringFont font = EngineeringFont.architectural,
    double fontSize = 13.0,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 0.5,
    double height = 1.2,
    Shadows? shadows,
  }) {
    return getTextStyle(
      font: font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  /// Preset font sizes for engineering notes
  static const double fontSizeSmall = 11.0;
  static const double fontSizeMedium = 13.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeHeader = 20.0;
  static const double fontSizeTitle = 24.0;
}

typedef Shadows = List<Shadow>;
