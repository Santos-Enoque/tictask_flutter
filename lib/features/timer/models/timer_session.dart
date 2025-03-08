import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'timer_session.g.dart';

@HiveType(typeId: 6)
enum SessionType {
  @HiveField(0)
  pomodoro,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak
}

@HiveType(typeId: 2)
class TimerSession extends Equatable {
  TimerSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.type,
    required this.completed,
    String? id,
    DateTime? date,
    this.taskId,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  // Factory method to create a completed session
  factory TimerSession.completed({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSession(
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
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSession(
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      type: type,
      completed: false,
      taskId: taskId,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int startTime; // Unix timestamp

  @HiveField(3)
  final int endTime; // Unix timestamp

  @HiveField(4)
  final int duration; // Duration in seconds

  @HiveField(5)
  final SessionType type;

  @HiveField(6)
  final bool completed;

  @HiveField(7)
  final String? taskId;

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
