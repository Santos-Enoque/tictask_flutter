import 'package:equatable/equatable.dart';

/// Entity class for timer configuration
class TimerConfigEntity extends Equatable {
  final String id;
  final int pomoDuration; // Focus duration in seconds
  final int shortBreakDuration; // Short break duration in seconds
  final int longBreakDuration; // Long break duration in seconds
  final int longBreakInterval; // Number of pomodoros before a long break

  const TimerConfigEntity({
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

  @override
  List<Object?> get props => [
        id,
        pomoDuration,
        shortBreakDuration,
        longBreakDuration,
        longBreakInterval,
      ];
}
