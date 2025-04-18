import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tictask/app/constants/enums.dart';

/// Domain entity for application settings
class SettingsEntity extends Equatable {
  final ThemePreference themePreference;
  final bool notificationsEnabled;
  final bool soundsEnabled;
  final bool vibrationEnabled;
  final bool syncEnabled;

  const SettingsEntity({
    this.themePreference = ThemePreference.system,
    this.notificationsEnabled = true,
    this.soundsEnabled = true,
    this.vibrationEnabled = true,
    this.syncEnabled = true,
  });

  /// Convert ThemePreference to Flutter's ThemeMode
  ThemeMode get themeMode {
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

  /// Create a copy with updated fields
  SettingsEntity copyWith({
    ThemePreference? themePreference,
    bool? notificationsEnabled,
    bool? soundsEnabled,
    bool? vibrationEnabled,
    bool? syncEnabled,
  }) {
    return SettingsEntity(
      themePreference: themePreference ?? this.themePreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }

  @override
  List<Object?> get props => [
        themePreference,
        notificationsEnabled,
        soundsEnabled,
        vibrationEnabled,
        syncEnabled,
      ];
}
