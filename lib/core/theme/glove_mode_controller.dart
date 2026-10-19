import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_controller.dart';

@immutable
class GloveModeState {
  final bool isGloveMode;

  const GloveModeState({
    this.isGloveMode = false,
  });

  /// Touch targets: >= 56dp in glove mode, otherwise 48dp (outdoor) or 44dp (standard)
  double minTouchTarget(bool isOutdoor) {
    if (isGloveMode) return 56.0;
    return isOutdoor ? 48.0 : 44.0;
  }

  /// Pen width: >= 4.0px in glove mode, otherwise 3.5px (outdoor) or 3.0px (standard)
  double minPenWidth(bool isOutdoor) {
    if (isGloveMode) return 4.0;
    return isOutdoor ? 3.5 : 3.0;
  }

  /// Tap vs drag threshold factor (touch slop multiplier)
  double get dragThresholdFactor => isGloveMode ? 2.25 : 1.0;

  /// Tap distance tolerance in normalized coordinates (0.0 .. 1.0)
  double get tapDistanceThreshold => isGloveMode ? 0.045 : 0.02;

  /// Icon size: 28dp in glove mode, otherwise 24dp (outdoor) or 22dp (standard)
  double iconSize(bool isOutdoor) {
    if (isGloveMode) return 28.0;
    return isOutdoor ? 24.0 : 22.0;
  }

  GloveModeState copyWith({
    bool? isGloveMode,
  }) {
    return GloveModeState(
      isGloveMode: isGloveMode ?? this.isGloveMode,
    );
  }
}

class GloveModeController extends StateNotifier<GloveModeState> {
  static const _prefKey = 'field_glove_mode_v1';
  final SharedPreferences? _prefs;

  GloveModeController(this._prefs) : super(const GloveModeState()) {
    _loadPersistedState();
  }

  void _loadPersistedState() {
    if (_prefs == null) return;
    final saved = _prefs.getBool(_prefKey);
    if (saved != null) {
      state = state.copyWith(isGloveMode: saved);
    }
  }

  Future<void> toggleGloveMode() async {
    await setGloveMode(!state.isGloveMode);
  }

  Future<void> setGloveMode(bool enabled) async {
    state = state.copyWith(isGloveMode: enabled);
    final p = _prefs;
    if (p != null) {
      await p.setBool(_prefKey, enabled);
    }
  }
}

final gloveModeProvider = StateNotifierProvider<GloveModeController, GloveModeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GloveModeController(prefs);
});
