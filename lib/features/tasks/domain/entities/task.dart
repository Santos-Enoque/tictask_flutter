// lib/features/tasks/domain/entities/task.dart
import 'package:equatable/equatable.dart';

enum TaskStatus {
  todo,
  inProgress,
  completed
}

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  final int pomodorosCompleted;
  final int? estimatedPomodoros;
  final int startDate;
  final int endDate;
  final bool ongoing;
  final bool hasReminder;
  final int? reminderTime;
  final String projectId;

  const Task({
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
  });

  // Returns a new task marked as in progress
  Task markAsInProgress() {
    return copyWith(
      status: TaskStatus.inProgress,
    );
  }

  // Returns a new task marked as completed
  Task markAsCompleted() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return copyWith(
      status: TaskStatus.completed,
      updatedAt: now,
      completedAt: now,
    );
  }

  // Returns a new task with incremented pomodoro count
  Task incrementPomodoro() {
    return copyWith(
      pomodorosCompleted: pomodorosCompleted + 1,
    );
  }

  // Create a copy with updated fields
  Task copyWith({
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
    return Task(
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

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    createdAt,
    updatedAt,
    completedAt,
    pomodorosCompleted,
    estimatedPomodoros,
    startDate,
    endDate,
    ongoing,
    hasReminder,
    reminderTime,
    projectId,
  ];
}
