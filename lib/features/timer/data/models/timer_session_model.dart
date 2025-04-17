import 'package:hive/hive.dart';
import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:uuid/uuid.dart';

part 'timer_session_model.g.dart';

@HiveType(typeId: 6)
enum SessionTypeModel {
  @HiveField(0)
  pomodoro,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak
}

@HiveType(typeId: 2)
class TimerSessionModel extends TimerSession {
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
  final SessionTypeModel typeModel;

  @HiveField(6)
  @override
  final bool completed;

  @HiveField(7)
  @override
  final String? taskId;

  TimerSessionModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.typeModel,
    required this.completed,
    this.taskId,
  }) : super(
          id: id,
          date: date,
          startTime: startTime,
          endTime: endTime,
          duration: duration,
          type: _mapTypeModelToDomain(typeModel),
          completed: completed,
          taskId: taskId,
        );

  // Map type model to domain
  static SessionType _mapTypeModelToDomain(SessionTypeModel typeModel) {
    switch (typeModel) {
      case SessionTypeModel.pomodoro:
        return SessionType.pomodoro;
      case SessionTypeModel.shortBreak:
        return SessionType.shortBreak;
      case SessionTypeModel.longBreak:
        return SessionType.longBreak;
    }
  }

  // Map domain type to model
  static SessionTypeModel _mapTypeDomainToModel(SessionType type) {
    switch (type) {
      case SessionType.pomodoro:
        return SessionTypeModel.pomodoro;
      case SessionType.shortBreak:
        return SessionTypeModel.shortBreak;
      case SessionType.longBreak:
        return SessionTypeModel.longBreak;
    }
  }

  // Factory method to create from domain entity
  factory TimerSessionModel.fromEntity(TimerSession entity) {
    return TimerSessionModel(
      id: entity.id,
      date: entity.date,
      startTime: entity.startTime,
      endTime: entity.endTime,
      duration: entity.duration,
      typeModel: _mapTypeDomainToModel(entity.type),
      completed: entity.completed,
      taskId: entity.taskId,
    );
  }

  // Factory method to create a completed session
  factory TimerSessionModel.completed({
    required int startTime,
    required int endTime,
    required int duration,
    required SessionType type,
    String? taskId,
  }) {
    final id = const Uuid().v4();
    return TimerSessionModel(
      id: id,
      date: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      typeModel: _mapTypeDomainToModel(type),
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
    final id = const Uuid().v4();
    return TimerSessionModel(
      id: id,
      date: DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      typeModel: _mapTypeDomainToModel(type),
      completed: false,
      taskId: taskId,
    );
  }

  // Create from JSON for API
  factory TimerSessionModel.fromJson(Map<String, dynamic> json) {
    return TimerSessionModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as int,
      endTime: json['end_time'] as int,
      duration: json['duration'] as int,
      typeModel: SessionTypeModel.values[json['type'] as int],
      completed: json['completed'] as bool,
      taskId: json['task_id'] as String?,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'type': typeModel.index,
      'completed': completed,
      'task_id': taskId,
    };
  }
}
