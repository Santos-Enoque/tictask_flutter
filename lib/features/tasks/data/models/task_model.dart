// lib/features/tasks/data/models/task_model.dart
import 'package:hive/hive.dart';
import 'package:tictask/features/tasks/domain/entities/task.dart';

@HiveType(typeId: 10)
class TaskModel extends Task {

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
    required super.id,
    required super.title,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.pomodorosCompleted,
    required super.startDate,
    required super.endDate,
    required super.ongoing,
    super.description,
    super.completedAt,
    super.estimatedPomodoros,
    super.hasReminder = false,
    super.reminderTime,
    super.projectId = 'inbox',
  });

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
