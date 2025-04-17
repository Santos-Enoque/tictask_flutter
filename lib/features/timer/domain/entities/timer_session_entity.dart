// lib/features/timer/domain/entities/timer_session_entity.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Type of timer session
enum SessionType {
  pomodoro,
  shortBreak,
  longBreak
}

/// Entity class for timer sessions
class TimerSessionEntity extends Equatable {
  final String id;
  final DateTime date;
  final int startTime; // Unix timestamp
  final int endTime; // Unix timestamp
  final int duration; // Duration in seconds
  final SessionType type;
  final bool completed;
  final String? taskId;

  const TimerSessionEntity({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.type,
    required this.completed,
    this.taskId,
  });

  // Factory method to create a completed session
  static TimerSessionEntity completed({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
    String? id,
    DateTime? date,
  }) {
    return TimerSessionEntity(
      id: id ?? const Uuid().v4(),
      date: date ?? DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      type: type,
      completed: true,
      taskId: taskId,
    );
  }

  // Factory method to create an interrupted session
  static TimerSessionEntity interrupted({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
    String? id,
    DateTime? date,
  }) {
    return TimerSessionEntity(
      id: id ?? const Uuid().v4(),
      date: date ?? DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      type: type,
      completed: false,
      taskId: taskId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        startTime,
        endTime,
        duration,
        type,
        completed,
        taskId,
      ];
}