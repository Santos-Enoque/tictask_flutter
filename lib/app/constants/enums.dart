import 'package:hive/hive.dart';

part 'enums.g.dart';

/// Task status enum
@HiveType(typeId: 7)
enum TaskStatus {
  @HiveField(0)
  todo('To Do'),

  @HiveField(1)
  inProgress('In Progress'),

  @HiveField(2)
  completed('Completed');

  final String displayName;

  const TaskStatus(this.displayName);
}

/// Duration units for timer settings
@HiveType(typeId: 8)
enum DurationUnit {
  @HiveField(0)
  minutes('Minutes'),

  @HiveField(1)
  seconds('Seconds');

  final String displayName;

  const DurationUnit(this.displayName);
}

/// User theme preference
@HiveType(typeId: 9)
enum ThemePreference {
  @HiveField(0)
  system('System'),

  @HiveField(1)
  light('Light'),

  @HiveField(2)
  dark('Dark');

  final String displayName;

  const ThemePreference(this.displayName);
}
