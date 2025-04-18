import 'package:flutter/material.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';

/// Interface defining settings repository operations
abstract class ISettingsRepository {
  /// Get complete settings entity
  Future<SettingsEntity> getSettings();
  
  /// Save complete settings entity
  Future<void> saveSettings(SettingsEntity settings);
  
  /// Get theme preference
  Future<ThemePreference> getThemePreference();
  
  /// Save theme preference
  Future<void> saveThemePreference(ThemePreference preference);
  
  /// Get theme mode
  ThemeMode getThemeMode();
  
  /// Save theme mode
  Future<void> saveThemeMode(ThemeMode themeMode);
  
  /// Get notifications enabled setting
  Future<bool> getNotificationsEnabled();
  
  /// Save notifications enabled setting
  Future<void> saveNotificationsEnabled(bool enabled);
  
  /// Get sounds enabled setting
  Future<bool> getSoundsEnabled();
  
  /// Save sounds enabled setting
  Future<void> saveSoundsEnabled(bool enabled);
  
  /// Get vibration enabled setting
  Future<bool> getVibrationEnabled();
  
  /// Save vibration enabled setting
  Future<void> saveVibrationEnabled(bool enabled);
  
  /// Get sync enabled setting
  Future<bool> getSyncEnabled();
  
  /// Save sync enabled setting
  Future<void> saveSyncEnabled(bool enabled);
}
