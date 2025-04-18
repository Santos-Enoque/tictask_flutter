part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final SettingsEntity settings;
  
  const SettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [settings];
  
  ThemeMode get themeMode => settings.themeMode;
  
  SettingsLoaded copyWith({
    SettingsEntity? settings,
  }) {
    return SettingsLoaded(
      settings ?? this.settings,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  
  const SettingsError(this.message);
  
  @override
  List<Object?> get props => [message];
}