import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String engineerName;
  final String engineerTitle;
  final String employeeId;
  final String company;
  final ThemeMode themeMode;
  final bool autoDownloadDrawings;
  final String securityPin;
  final bool isPinRequired;

  const SettingsState({
    this.engineerName = 'Yadhukrishna',
    this.engineerTitle = 'Lead Field Piping & Inspection Engineer',
    this.employeeId = 'ENG-8842-FE',
    this.company = 'Middle East EPC Consortium',
    this.themeMode = ThemeMode.dark,
    this.autoDownloadDrawings = true,
    this.securityPin = '1234',
    this.isPinRequired = true,
  });

  SettingsState copyWith({
    String? engineerName,
    String? engineerTitle,
    String? employeeId,
    String? company,
    ThemeMode? themeMode,
    bool? autoDownloadDrawings,
    String? securityPin,
    bool? isPinRequired,
  }) {
    return SettingsState(
      engineerName: engineerName ?? this.engineerName,
      engineerTitle: engineerTitle ?? this.engineerTitle,
      employeeId: employeeId ?? this.employeeId,
      company: company ?? this.company,
      themeMode: themeMode ?? this.themeMode,
      autoDownloadDrawings: autoDownloadDrawings ?? this.autoDownloadDrawings,
      securityPin: securityPin ?? this.securityPin,
      isPinRequired: isPinRequired ?? this.isPinRequired,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('engineer_name') ?? state.engineerName;
      final title = prefs.getString('engineer_title') ?? state.engineerTitle;
      final id = prefs.getString('employee_id') ?? state.employeeId;
      final company = prefs.getString('company') ?? state.company;
      final pin = prefs.getString('security_pin') ?? state.securityPin;
      final isPinReq = prefs.getBool('is_pin_required') ?? state.isPinRequired;
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      final autoDl = prefs.getBool('auto_download') ?? true;

      state = state.copyWith(
        engineerName: name,
        engineerTitle: title,
        employeeId: id,
        company: company,
        securityPin: pin,
        isPinRequired: isPinReq,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        autoDownloadDrawings: autoDl,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String title,
    required String employeeId,
    required String company,
  }) async {
    state = state.copyWith(
      engineerName: name,
      engineerTitle: title,
      employeeId: employeeId,
      company: company,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('engineer_name', name);
    await prefs.setString('engineer_title', title);
    await prefs.setString('employee_id', employeeId);
    await prefs.setString('company', company);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
  }

  Future<void> setSecurityPin(String pin) async {
    state = state.copyWith(securityPin: pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_pin', pin);
  }

  Future<void> togglePinRequired(bool required) async {
    state = state.copyWith(isPinRequired: required);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pin_required', required);
  }

  Future<void> toggleAutoDownload(bool auto) async {
    state = state.copyWith(autoDownloadDrawings: auto);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_download', auto);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
