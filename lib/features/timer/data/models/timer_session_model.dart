import 'package:hive/hive.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:uuid/uuid.dart';

part 'timer_session_model.g.dart';

@HiveType(typeId: 2)
class TimerSessionModel extends TimerSessionEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final DateTime date;

  @HiveField(2)
  @override
  final int startTime;

  @HiveField(3)
  @override
  final int endTime;

  @HiveField(4)
  @override
  final int duration;

  @HiveField(5)
  @override
  final SessionType type;

  @HiveField(6)
  @override
  final bool completed;

  @HiveField(7)
  @override
  final String? taskId;

  const TimerSessionModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.type,
    required this.completed,
    this.taskId,
  }) : super(
          id: id,
          date: date,
          startTime: startTime,
          endTime: endTime,
          duration: duration,
          type: type,
          completed: completed,
          taskId: taskId,
        );

  // Constructor with default date parameter
  TimerSessionModel.withDate({
    required String id,
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    required bool completed,
    String? taskId,
    DateTime? date,
  }) : this(
          id: id,
          date: date ?? DateTime.now(),
          startTime: startTime,
          endTime: endTime,
          duration: duration,
          type: type,
          completed: completed,
          taskId: taskId,
        );

  // Factory method to create a completed session
  factory TimerSessionModel.completed({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSessionModel(
      id: const Uuid().v4(),
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
  factory TimerSessionModel.interrupted({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    return TimerSessionModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      type: type,
      completed: false,
      taskId: taskId,
    );
  }

  // Factory to create from domain entity
  factory TimerSessionModel.fromEntity(TimerSessionEntity entity) {
    return TimerSessionModel(
      id: entity.id,
      date: entity.date,
      startTime: entity.startTime,
      endTime: entity.endTime,
      duration: entity.duration,
      type: entity.type,
      completed: entity.completed,
      taskId: entity.taskId,
    );
  }

  // Convert to map for API
  Map<String, dynamic> toJson({String? userId}) {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'type': type.index,
      'completed': completed,
      'task_id': taskId,
      'user_id': userId,
    };
  }

  // Create from map from API
  factory TimerSessionModel.fromJson(Map<String, dynamic> json) {
    return TimerSessionModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as int,
      endTime: json['end_time'] as int,
      duration: json['duration'] as int,
      type: SessionType.values[json['type'] as int],
      completed: json['completed'] as bool,
      taskId: json['task_id'] as String?,
    );
  }
}
