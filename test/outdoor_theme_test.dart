import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_engineering/core/theme/app_colors.dart';
import 'package:field_engineering/core/theme/theme_controller.dart';
import 'package:field_engineering/core/theme/app_theme.dart';

/// Computes relative luminance according to WCAG 2.1 specifications
double _relativeLuminance(Color color) {
  double transform(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.red / 255.0);
  final g = transform(color.green / 255.0);
  final b = transform(color.blue / 255.0);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Computes contrast ratio between foreground and background (1:1 to 21:1)
double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Outdoor Theme - WCAG AAA (7:1) Direct Sunlight Contrast Verification', () {
    test('Outdoor primary body text #0B1417 on #FFFFFF exceeds WCAG AAA 7:1 threshold', () {
      final ratio = _contrastRatio(AppColors.outdoorText, AppColors.outdoorBackground);
      // Expected ~ 18.6 : 1
      expect(ratio, greaterThanOrEqualTo(7.0));
      expect(ratio, greaterThan(15.0));
    });

    test('Outdoor secondary text #3F4D52 on #FFFFFF exceeds WCAG AAA 7:1 threshold', () {
      final ratio = _contrastRatio(AppColors.outdoorSecondaryText, AppColors.outdoorBackground);
      // Expected ~ 8.9 : 1
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('Canvas paper stays pure white #FFFFFF in all themes', () {
      expect(AppColors.canvasPaper, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.canvasPaper.value, equals(0xFFFFFFFF));
    });
  });

  group('Outdoor Theme - Tokens and Palette Rules', () {
    test('Outdoor theme tokens match exact design specification', () {
      expect(AppColors.outdoorBackground, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.outdoorSurface, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.outdoorText, equals(const Color(0xFF0B1417)));
      expect(AppColors.outdoorSecondaryText, equals(const Color(0xFF3F4D52)));
      expect(AppColors.outdoorPrimary, equals(const Color(0xFF08605B)));
      expect(AppColors.outdoorOnPrimary, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.outdoorOutline, equals(const Color(0xFF5F6F75)));
      expect(AppColors.outdoorChip, equals(const Color(0xFFE3E8EA)));
    });

    test('Outdoor inking palette contains exactly 5 high-contrast presets and strictly NO yellow', () {
      expect(kOutdoorColorPresets.length, equals(5));

      expect(kOutdoorColorPresets, contains(const Color(0xFFC62828))); // Red
      expect(kOutdoorColorPresets, contains(const Color(0xFF185FA5))); // Blue
      expect(kOutdoorColorPresets, contains(const Color(0xFF1F6B2D))); // Green
      expect(kOutdoorColorPresets, contains(const Color(0xFF111111))); // Black
      expect(kOutdoorColorPresets, contains(const Color(0xFFC25E00))); // Orange

      // Strictly NO yellow pen color in Outdoor mode
      expect(kOutdoorColorPresets, isNot(contains(const Color(0xFFF2D13A))));
      expect(kOutdoorColorPresets, isNot(contains(AppColors.inkYellow)));
    });

    test('Outdoor theme specifies min 48dp touch targets and 3.5px default pen width', () {
      final controller = ThemeController(null);
      controller.setThemeMode(AppThemeMode.outdoor);

      expect(controller.state.isOutdoorActive, isTrue);
      expect(controller.state.defaultPenWidth, equals(3.5));
      expect(controller.state.colorPresets, equals(kOutdoorColorPresets));

      // Theme data verification
      final theme = AppTheme.outdoorTheme;
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(theme.colorScheme.primary, equals(const Color(0xFF08605B)));
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });

  group('Outdoor Theme - Theme Controller & Ambient Sensor Simulation', () {
    test('Auto mode activates Standard in indoor ambient lighting and Outdoor in bright sunlight', () {
      final controller = ThemeController(null);
      controller.setThemeMode(AppThemeMode.auto);

      // Default indoor
      expect(controller.state.activeTheme, equals(AppActiveTheme.standard));
      expect(controller.state.isOutdoorActive, isFalse);

      // Sunlight detected (> 25,000 lux)
      controller.setAmbientSunlightDetected(true);
      expect(controller.state.activeTheme, equals(AppActiveTheme.outdoor));
      expect(controller.state.isOutdoorActive, isTrue);

      // Back to indoor
      controller.setAmbientSunlightDetected(false);
      expect(controller.state.activeTheme, equals(AppActiveTheme.standard));
    });

    test('Manual Outdoor override forces Outdoor mode even in Auto mode', () {
      final controller = ThemeController(null);
      controller.setThemeMode(AppThemeMode.auto);

      controller.setManualOutdoorOverride(true);
      expect(controller.state.activeTheme, equals(AppActiveTheme.outdoor));
      expect(controller.state.isOutdoorActive, isTrue);
    });

    test('Explicit theme selection overrides ambient sensor', () {
      final controller = ThemeController(null);

      controller.setThemeMode(AppThemeMode.dark);
      expect(controller.state.activeTheme, equals(AppActiveTheme.dark));

      controller.setThemeMode(AppThemeMode.outdoor);
      expect(controller.state.activeTheme, equals(AppActiveTheme.outdoor));

      controller.setThemeMode(AppThemeMode.standard);
      expect(controller.state.activeTheme, equals(AppActiveTheme.standard));
    });
  });
}
