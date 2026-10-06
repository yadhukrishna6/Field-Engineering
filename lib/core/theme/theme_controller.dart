import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  static const String _kThemePrefKey = 'selected_theme_mode_pref';

  ThemeController() : super(ThemeMode.system) {
    _loadPersistedTheme();
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_kThemePrefKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < ThemeMode.values.length) {
        state = ThemeMode.values[savedIndex];
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemePrefKey, mode.index);
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (state == ThemeMode.system) {
      // If currently following system dark, switch to light; otherwise dark
      if (currentBrightness == Brightness.dark) {
        await setThemeMode(ThemeMode.light);
      } else {
        await setThemeMode(ThemeMode.dark);
      }
    } else if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});
