import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_theme.dart';

enum AppThemeMode {
  auto('Auto (Ambient Light)'),
  standard('Standard (Desert Light)'),
  outdoor('Outdoor (Sunlight High Contrast)'),
  dark('Dark (Desert Dark)');

  final String label;
  const AppThemeMode(this.label);
}

enum AppActiveTheme {
  standard,
  outdoor,
  dark,
}

class ThemeState {
  final AppThemeMode themeMode;
  final bool isDirectSunlightDetected; // Ambient light sensor (> 25,000 lux)
  final bool manualOutdoorOverride;    // Manual ambient override switch

  const ThemeState({
    this.themeMode = AppThemeMode.auto,
    this.isDirectSunlightDetected = false,
    this.manualOutdoorOverride = false,
  });

  AppActiveTheme get activeTheme {
    switch (themeMode) {
      case AppThemeMode.standard:
        return AppActiveTheme.standard;
      case AppThemeMode.outdoor:
        return AppActiveTheme.outdoor;
      case AppThemeMode.dark:
        return AppActiveTheme.dark;
      case AppThemeMode.auto:
        if (isDirectSunlightDetected || manualOutdoorOverride) {
          return AppActiveTheme.outdoor;
        }
        return AppActiveTheme.standard;
    }
  }

  bool get isOutdoorActive => activeTheme == AppActiveTheme.outdoor;
  bool get isDarkActive => activeTheme == AppActiveTheme.dark;

  ThemeData get themeData {
    switch (activeTheme) {
      case AppActiveTheme.outdoor:
        return AppTheme.outdoorTheme;
      case AppActiveTheme.dark:
        return AppTheme.darkTheme;
      case AppActiveTheme.standard:
      default:
        return AppTheme.lightTheme;
    }
  }

  List<Color> get colorPresets {
    return isOutdoorActive ? kOutdoorColorPresets : kReferenceColorPresets;
  }

  double get defaultPenWidth => isOutdoorActive ? 3.5 : 3.0;

  ThemeState copyWith({
    AppThemeMode? themeMode,
    bool? isDirectSunlightDetected,
    bool? manualOutdoorOverride,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDirectSunlightDetected: isDirectSunlightDetected ?? this.isDirectSunlightDetected,
      manualOutdoorOverride: manualOutdoorOverride ?? this.manualOutdoorOverride,
    );
  }
}

class ThemeController extends StateNotifier<ThemeState> {
  static const _prefKey = 'app_theme_mode_v2';
  final SharedPreferences? _prefs;

  ThemeController(this._prefs) : super(const ThemeState()) {
    _loadPersistedTheme();
  }

  void _loadPersistedTheme() {
    if (_prefs == null) return;
    final saved = _prefs.getString(_prefKey);
    if (saved != null) {
      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => AppThemeMode.auto,
      );
      state = state.copyWith(themeMode: mode);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final p = _prefs; if (p != null) { await p.setString(_prefKey, mode.name); }
  }

  void setAmbientSunlightDetected(bool isBrightSunlight) {
    state = state.copyWith(isDirectSunlightDetected: isBrightSunlight);
  }

  void setManualOutdoorOverride(bool override) {
    state = state.copyWith(manualOutdoorOverride: override);
  }

  void cycleTheme() {
    final nextIndex = (state.themeMode.index + 1) % AppThemeMode.values.length;
    setThemeMode(AppThemeMode.values[nextIndex]);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(prefs);
});
