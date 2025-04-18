import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/settings/domain/entities/settings_entity.dart';

// This will be generated by Hive
part 'settings_model.g.dart';

@HiveType(typeId: 12) // Make sure this ID doesn't conflict with existing types
class SettingsModel extends SettingsEntity {
  @HiveField(0)
  @override
  final ThemePreference themePreference;
  
  @HiveField(1)
  @override
  final bool notificationsEnabled;
  
  @HiveField(2)
  @override
  final bool soundsEnabled;
  
  @HiveField(3)
  @override
  final bool vibrationEnabled;
  
  @HiveField(4)
  @override
  final bool syncEnabled;

  const SettingsModel({
    this.themePreference = ThemePreference.system,
    this.notificationsEnabled = true,
    this.soundsEnabled = true,
    this.vibrationEnabled = true,
    this.syncEnabled = true,
  }) : super(
          themePreference: themePreference,
          notificationsEnabled: notificationsEnabled,
          soundsEnabled: soundsEnabled,
          vibrationEnabled: vibrationEnabled,
          syncEnabled: syncEnabled,
        );

  /// Create a copy with updated fields
  @override
  SettingsModel copyWith({
    ThemePreference? themePreference,
    bool? notificationsEnabled,
    bool? soundsEnabled,
    bool? vibrationEnabled,
    bool? syncEnabled,
  }) {
    return SettingsModel(
      themePreference: themePreference ?? this.themePreference,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }

  /// Factory to create from domain entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      themePreference: entity.themePreference,
      notificationsEnabled: entity.notificationsEnabled,
      soundsEnabled: entity.soundsEnabled,
      vibrationEnabled: entity.vibrationEnabled,
      syncEnabled: entity.syncEnabled,
    );
  }

  /// Default settings model
  static const SettingsModel defaultSettings = SettingsModel();
}
