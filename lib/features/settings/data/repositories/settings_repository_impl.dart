import 'package:flutter/material.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/settings/data/datasource/settings_local_data_source.dart';
import 'package:tictask/features/settings/data/models/settings_model.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';
import 'package:tictask/features/settings/domain/repositories/i_settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  final SettingsLocalDataSource _localDataSource;
  
  SettingsRepositoryImpl(this._localDataSource);
  
  Future<void> init() async {
    await _localDataSource.init();
  }
  
  @override
  Future<SettingsEntity> getSettings() async {
    return await _localDataSource.getSettings();
  }
  
  @override
  Future<void> saveSettings(SettingsEntity settings) async {
    final settingsModel = settings is SettingsModel
        ? settings
        : SettingsModel.fromEntity(settings);
    
    await _localDataSource.saveSettings(settingsModel);
  }
  
  @override
  Future<ThemePreference> getThemePreference() async {
    return await _localDataSource.getThemePreference();
  }
  
  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    await _localDataSource.saveThemePreference(preference);
  }
  
  @override
  ThemeMode getThemeMode() {
    // This is a synchronous method, but it depends on an async getThemePreference
    // We'll use the default value and assume it will be updated later
    final ThemePreference themePreference = ThemePreference.system;
    
    switch (themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
      default:
        return ThemeMode.system;
    }
  }
  
  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    ThemePreference preference;
    
    switch (themeMode) {
      case ThemeMode.light:
        preference = ThemePreference.light;
        break;
      case ThemeMode.dark:
        preference = ThemePreference.dark;
        break;
      case ThemeMode.system:
      default:
        preference = ThemePreference.system;
        break;
    }
    
    await saveThemePreference(preference);
  }
  
  @override
  Future<bool> getNotificationsEnabled() async {
    return await _localDataSource.getNotificationsEnabled();
  }
  
  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _localDataSource.saveNotificationsEnabled(enabled);
  }
  
  @override
  Future<bool> getSoundsEnabled() async {
    return await _localDataSource.getSoundsEnabled();
  }
  
  @override
  Future<void> saveSoundsEnabled(bool enabled) async {
    await _localDataSource.saveSoundsEnabled(enabled);
  }
  
  @override
  Future<bool> getVibrationEnabled() async {
    return await _localDataSource.getVibrationEnabled();
  }
  
  @override
  Future<void> saveVibrationEnabled(bool enabled) async {
    await _localDataSource.saveVibrationEnabled(enabled);
  }
  
  @override
  Future<bool> getSyncEnabled() async {
    return await _localDataSource.getSyncEnabled();
  }
  
  @override
  Future<void> saveSyncEnabled(bool enabled) async {
    await _localDataSource.saveSyncEnabled(enabled);
  }
}