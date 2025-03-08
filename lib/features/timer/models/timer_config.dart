import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'timer_config.g.dart';

@HiveType(typeId: 1)
class TimerConfig extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int pomoDuration; // Focus duration in seconds

  @HiveField(2)
  final int shortBreakDuration; // Short break duration in seconds

  @HiveField(3)
  final int longBreakDuration; // Long break duration in seconds

  @HiveField(4)
  final int longBreakInterval; // Number of pomodoros before a long break

  const TimerConfig({
    this.id = 'default',
    this.pomoDuration = 25 * 60, // 25 minutes
    this.shortBreakDuration = 5 * 60, // 5 minutes
    this.longBreakDuration = 15 * 60, // 15 minutes
    this.longBreakInterval = 4, // After 4 pomodoros
  });

  // Convenient getters for minutes
  int get pomodoroDurationInMinutes => pomoDuration ~/ 60;
  int get shortBreakDurationInMinutes => shortBreakDuration ~/ 60;
  int get longBreakDurationInMinutes => longBreakDuration ~/ 60;

  // Create a copy with updated fields
  TimerConfig copyWith({
    String? id,
    int? pomoDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? longBreakInterval,
  }) {
    return TimerConfig(
      id: id ?? this.id,
      pomoDuration: pomoDuration ?? this.pomoDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    );
  }

  // Default config
  static const TimerConfig defaultConfig = TimerConfig();

  @override
  List<Object?> get props => [
        id,
        pomoDuration,
        shortBreakDuration,
        longBreakDuration,
        longBreakInterval,
      ];
}