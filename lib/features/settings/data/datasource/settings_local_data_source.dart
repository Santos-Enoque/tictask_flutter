import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/core/constants/storage_constants.dart';
import 'package:tictask/features/settings/data/models/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<void> init();
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
  Future<ThemePreference> getThemePreference();
  Future<void> saveThemePreference(ThemePreference preference);
  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);
  Future<bool> getSoundsEnabled();
  Future<void> saveSoundsEnabled(bool enabled);
  Future<bool> getVibrationEnabled();
  Future<void> saveVibrationEnabled(bool enabled);
  Future<bool> getSyncEnabled();
  Future<void> saveSyncEnabled(bool enabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  late Box<SettingsModel> _settingsBox;
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(SettingsModelAdapter());
      }

      // Open box
      _settingsBox = await Hive.openBox<SettingsModel>(StorageConstants.settingsBox);
      
      // Initialize with default values if empty
      if (_settingsBox.isEmpty) {
        await _settingsBox.put('default', SettingsModel.defaultSettings);
      }
      
      // Get shared preferences instance
      _prefs = await SharedPreferences.getInstance();
      
      print('SettingsLocalDataSource initialized successfully');
    } catch (e) {
      print('Error initializing SettingsLocalDataSource: $e');
      
      // Try to recover by creating default instances
      _settingsBox = await Hive.openBox<SettingsModel>(StorageConstants.settingsBox);
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize with default values
      if (_settingsBox.isEmpty) {
        await _settingsBox.put('default', SettingsModel.defaultSettings);
      }
    }
  }

  @override
  Future<SettingsModel> getSettings() async {
    return _settingsBox.get('default') ?? SettingsModel.defaultSettings;
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _settingsBox.put('default', settings);
  }

  @override
  Future<ThemePreference> getThemePreference() async {
    final settings = await getSettings();
    return settings.themePreference;
  }

  @override
  Future<void> saveThemePreference(ThemePreference preference) async {
    final settings = await getSettings();
    final updated = settings.copyWith(themePreference: preference);
    await saveSettings(updated);
    
    // Also save in SharedPreferences for backward compatibility
    await _prefs.setInt(StorageConstants.themeModePrefKey, preference.index);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    // Check SharedPreferences first for backward compatibility
    if (_prefs.containsKey(StorageConstants.notificationsEnabledPrefKey)) {
      return _prefs.getBool(StorageConstants.notificationsEnabledPrefKey) ?? true;
    }
    
    final settings = await getSettings();
    return settings.notificationsEnabled;
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    final settings = await getSettings();
    final updated = settings.copyWith(notificationsEnabled: enabled);
    await saveSettings(updated);
    
    // Also save in SharedPreferences for backward compatibility
    await _prefs.setBool(StorageConstants.notificationsEnabledPrefKey, enabled);
  }

  @override
  Future<bool> getSoundsEnabled() async {
    // Check SharedPreferences first for backward compatibility
    if (_prefs.containsKey('sounds_enabled')) {
      return _prefs.getBool('sounds_enabled') ?? true;
    }
    
    final settings = await getSettings();
    return settings.soundsEnabled;
  }

  @override
  Future<void> saveSoundsEnabled(bool enabled) async {
    final settings = await getSettings();
    final updated = settings.copyWith(soundsEnabled: enabled);
    await saveSettings(updated);
    
    // Also save in SharedPreferences for backward compatibility
    await _prefs.setBool('sounds_enabled', enabled);
  }

  @override
  Future<bool> getVibrationEnabled() async {
    // Check SharedPreferences first for backward compatibility
    if (_prefs.containsKey('vibration_enabled')) {
      return _prefs.getBool('vibration_enabled') ?? true;
    }
    
    final settings = await getSettings();
    return settings.vibrationEnabled;
  }

  @override
  Future<void> saveVibrationEnabled(bool enabled) async {
    final settings = await getSettings();
    final updated = settings.copyWith(vibrationEnabled: enabled);
    await saveSettings(updated);
    
    // Also save in SharedPreferences for backward compatibility
    await _prefs.setBool('vibration_enabled', enabled);
  }

  @override
  Future<bool> getSyncEnabled() async {
    // Check SharedPreferences first for backward compatibility
    if (_prefs.containsKey(StorageConstants.syncEnabledPrefKey)) {
      return _prefs.getBool(StorageConstants.syncEnabledPrefKey) ?? true;
    }
    
    final settings = await getSettings();
    return settings.syncEnabled;
  }

  @override
  Future<void> saveSyncEnabled(bool enabled) async {
    final settings = await getSettings();
    final updated = settings.copyWith(syncEnabled: enabled);
    await saveSettings(updated);
    
    // Also save in SharedPreferences for backward compatibility
    await _prefs.setBool(StorageConstants.syncEnabledPrefKey, enabled);
  }
}
