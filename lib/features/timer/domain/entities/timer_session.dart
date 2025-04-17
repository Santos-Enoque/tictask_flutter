import 'package:equatable/equatable.dart';

enum SessionType {
  pomodoro,
  shortBreak,
  longBreak
}

class TimerSession extends Equatable {
  final String id;
  final DateTime date;
  final int startTime; // Unix timestamp
  final int endTime; // Unix timestamp
  final int duration; // Duration in seconds
  final SessionType type;
  final bool completed;
  final String? taskId;

  const TimerSession({
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
  factory TimerSession.completed({
    required String id,
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSession(
      id: id,
      date: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      type: type,
      completed: true,
      taskId: taskId,
    );
  }

  // Factory method to create an interrupted session
  factory TimerSession.interrupted({
    required String id,
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSession(
      id: id,
      date: DateTime.now(),
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
