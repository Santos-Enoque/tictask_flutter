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
    required this.dueDate,
    required this.ongoing,
    this.description,
    this.completedAt,
    this.estimatedPomodoros,
  });

  // Factory method to create a new task
  factory Task.create({
    required String title,
    required int dueDate,
    String? description,
    int? estimatedPomodoros,
    bool ongoing = false,
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
      dueDate: dueDate,
      ongoing: ongoing,
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
  final int dueDate;

  @HiveField(10)
  final bool ongoing;

  // Create a copy with updated fields
  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    int? updatedAt,
    int? completedAt,
    int? pomodorosCompleted,
    int? estimatedPomodoros,
    int? dueDate,
    bool? ongoing,
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
      dueDate: dueDate ?? this.dueDate,
      ongoing: ongoing ?? this.ongoing,
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
        dueDate,
        ongoing,
      ];
}
