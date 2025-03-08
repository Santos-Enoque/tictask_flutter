import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';

class SettingsRepository {
  late Box<dynamic> _settingsBox;

  // Initialize repository
  Future<void> init() async {
    // Open box
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);

    // Initialize with default values if empty
    if (!_settingsBox.containsKey(AppConstants.themeModePrefKey)) {
      await _settingsBox.put(
        AppConstants.themeModePrefKey,
        ThemePreference.system.index,
      );
    }

    if (!_settingsBox.containsKey(AppConstants.notificationsEnabledPrefKey)) {
      await _settingsBox.put(
        AppConstants.notificationsEnabledPrefKey,
        true,
      );
    }
  }

  // Get current theme preference
  ThemePreference getThemePreference() {
    final themeIndex = _settingsBox.get(
      AppConstants.themeModePrefKey,
      defaultValue: ThemePreference.system.index,
    ) as int;

    return ThemePreference.values[themeIndex];
  }

  // Save theme preference
  Future<void> saveThemePreference(ThemePreference preference) async {
    await _settingsBox.put(AppConstants.themeModePrefKey, preference.index);
  }

  // Get theme mode from preference
  ThemeMode getThemeMode() {
    final preference = getThemePreference();
    switch (preference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
      default:
        return ThemeMode.system;
    }
  }

  // Save theme mode
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    ThemePreference preference;
    switch (themeMode) {
      case ThemeMode.light:
        preference = ThemePreference.light;
      case ThemeMode.dark:
        preference = ThemePreference.dark;
      case ThemeMode.system:
      default:
        preference = ThemePreference.system;
    }

    await saveThemePreference(preference);
  }

  // Get notifications enabled
  bool getNotificationsEnabled() {
    return _settingsBox.get(
      AppConstants.notificationsEnabledPrefKey,
      defaultValue: true,
    ) as bool;
  }

  // Save notifications enabled
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.notificationsEnabledPrefKey, enabled);
  }

  // Clean up resources
  Future<void> close() async {
    await _settingsBox.close();
  }
}
