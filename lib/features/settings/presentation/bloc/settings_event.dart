part of 'settings_bloc.dart';
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateSettings extends SettingsEvent {
  final SettingsEntity settings;
  
  const UpdateSettings(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  
  const UpdateThemeMode(this.themeMode);
  
  @override
  List<Object?> get props => [themeMode];
}

class UpdateThemePreference extends SettingsEvent {
  final ThemePreference preference;
  
  const UpdateThemePreference(this.preference);
  
  @override
  List<Object?> get props => [preference];
}

class UpdateNotificationsEnabled extends SettingsEvent {
  final bool enabled;
  
  const UpdateNotificationsEnabled(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

class UpdateSoundsEnabled extends SettingsEvent {
  final bool enabled;
  
  const UpdateSoundsEnabled(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

class UpdateVibrationEnabled extends SettingsEvent {
  final bool enabled;
  
  const UpdateVibrationEnabled(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}

class UpdateSyncEnabled extends SettingsEvent {
  final bool enabled;
  
  const UpdateSyncEnabled(this.enabled);
  
  @override
  List<Object?> get props => [enabled];
}