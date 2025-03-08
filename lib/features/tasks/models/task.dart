import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 10)
class Task extends Equatable {
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

  // Factory method to create a new task
  factory Task.create({
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
    return Task(
      id: const Uuid().v4(),
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
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final TaskStatus status;

  @HiveField(4)
  final int createdAt;

  @HiveField(5)
  final int updatedAt;

  @HiveField(6)
  final int? completedAt;

  @HiveField(7)
  final int pomodorosCompleted;

  @HiveField(8)
  final int? estimatedPomodoros;

  @HiveField(9)
  final int startDate;

  @HiveField(10)
  final int endDate;

  @HiveField(11)
  final bool ongoing;

  @HiveField(12)
  final bool hasReminder;

  @HiveField(13)
  final int? reminderTime;

  @HiveField(14)
  final String projectId;

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

  // Mark task as completed
  Task markAsCompleted() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return copyWith(
      status: TaskStatus.completed,
      updatedAt: now,
      completedAt: now,
    );
  }

  // Mark task as in progress
  Task markAsInProgress() {
    return copyWith(
      status: TaskStatus.inProgress,
    );
  }

  // Increment pomodoro count
  Task incrementPomodoro() {
    return copyWith(
      pomodorosCompleted: pomodorosCompleted + 1,
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
