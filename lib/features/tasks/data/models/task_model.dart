// lib/features/tasks/data/models/task_model.dart
import 'package:hive/hive.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';

part 'task_model.g.dart';

@HiveType(typeId: 10)
class TaskModel extends TaskEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String title;

  @HiveField(2)
  @override
  final String? description;

  @HiveField(3)
  @override
  final TaskStatus status;

  @HiveField(4)
  @override
  final int createdAt;

  @HiveField(5)
  @override
  final int updatedAt;

  @HiveField(6)
  @override
  final int? completedAt;

  @HiveField(7)
  @override
  final int pomodorosCompleted;

  @HiveField(8)
  @override
  final int? estimatedPomodoros;

  @HiveField(9)
  @override
  final int startDate;

  @HiveField(10)
  @override
  final int endDate;

  @HiveField(11)
  @override
  final bool ongoing;

  @HiveField(12)
  @override
  final bool hasReminder;

  @HiveField(13)
  @override
  final int? reminderTime;

  @HiveField(14)
  @override
  final String projectId;

  // Create from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.values[json['status'] as int],
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      completedAt: json['completed_at'] as int?,
      pomodorosCompleted: json['pomodoros_completed'] as int,
      estimatedPomodoros: json['estimated_pomodoros'] as int?,
      startDate: json['start_date'] as int,
      endDate: json['end_date'] as int,
      ongoing: json['ongoing'] as bool,
      hasReminder: json['has_reminder'] as bool,
      reminderTime: json['reminder_time'] as int?,
      projectId: json['project_id'] as String,
    );
  }
  const TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.pomodorosCompleted,
    required this.startDate,
    required this.endDate,
    required this.ongoing,
    this.description,
    this.completedAt,
    this.estimatedPomodoros,
    this.hasReminder = false,
    this.reminderTime,
    this.projectId = 'inbox',
  }) : super(
          id: id,
          title: title,
          status: status,
          createdAt: createdAt,
          updatedAt: updatedAt,
          pomodorosCompleted: pomodorosCompleted,
          startDate: startDate,
          endDate: endDate,
          ongoing: ongoing,
          description: description,
          completedAt: completedAt,
          estimatedPomodoros: estimatedPomodoros,
          hasReminder: hasReminder,
          reminderTime: reminderTime,
          projectId: projectId,
        );

  // Factory to create a new task
  factory TaskModel.create({
    required String id,
    required String title,
    required int startDate,
    required int endDate,
    String? description,
    int? estimatedPomodoros,
    bool ongoing = false,
    bool hasReminder = false,
    int? reminderTime,
    String projectId = 'inbox',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TaskModel(
      id: id,
      title: title,
      description: description,
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
      pomodorosCompleted: 0,
      estimatedPomodoros: estimatedPomodoros,
      startDate: startDate,
      endDate: endDate,
      ongoing: ongoing,
      hasReminder: hasReminder,
      reminderTime: reminderTime,
      projectId: projectId,
    );
  }

  // Create a copy with updated fields
  @override
  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    int? updatedAt,
    int? completedAt,
    int? pomodorosCompleted,
    int? estimatedPomodoros,
    int? startDate,
    int? endDate,
    bool? ongoing,
    bool? hasReminder,
    int? reminderTime,
    String? projectId,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      completedAt: completedAt ?? this.completedAt,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ongoing: ongoing ?? this.ongoing,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      projectId: projectId ?? this.projectId,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
      'pomodoros_completed': pomodorosCompleted,
      'estimated_pomodoros': estimatedPomodoros,
      'start_date': startDate,
      'end_date': endDate,
      'ongoing': ongoing,
      'has_reminder': hasReminder,
      'reminder_time': reminderTime,
      'project_id': projectId,
    };
  }
}
