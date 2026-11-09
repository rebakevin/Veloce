import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The five local preferences (TECHNICAL.md §9), restored on every launch.
class PreferencesService {
  const PreferencesService(this._preferences);

  static const String themeModeKey = 'theme_mode';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String onboardingSeenKey = 'onboarding_seen';
  static const String lastSearchAreaKey = 'last_search_area';
  static const String lastTypeChipKey = 'last_type_chip';

  final SharedPreferences _preferences;

  ThemeMode get themeMode {
    final stored = _preferences.getString(themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _preferences.setString(themeModeKey, mode.name);

  bool get notificationsEnabled =>
      _preferences.getBool(notificationsEnabledKey) ?? true;

  Future<void> setNotificationsEnabled({required bool enabled}) =>
      _preferences.setBool(notificationsEnabledKey, enabled);

  bool get onboardingSeen => _preferences.getBool(onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() =>
      _preferences.setBool(onboardingSeenKey, true);

  String? get lastSearchArea => _preferences.getString(lastSearchAreaKey);

  Future<void> setLastSearchArea(String area) =>
      _preferences.setString(lastSearchAreaKey, area);

  String? get lastTypeChip => _preferences.getString(lastTypeChipKey);

  Future<void> setLastTypeChip(String chip) =>
      _preferences.setString(lastTypeChipKey, chip);
}
