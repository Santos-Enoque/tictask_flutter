part of 'task_bloc.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

final class LoadTasks extends TaskEvent {
  const LoadTasks();
}

final class LoadTasksByDate extends TaskEvent {
  const LoadTasksByDate(this.date);
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class LoadTasksInRange extends TaskEvent {
  const LoadTasksInRange(this.startDate, this.endDate);
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

final class AddTask extends TaskEvent {
  const AddTask({
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.estimatedPomodoros,
    this.ongoing = false,
    this.hasReminder = false,
    this.reminderTime,
    this.projectId = 'inbox', // Default to inbox
  });
  final String title;
  final String? description;
  final int? estimatedPomodoros;
  final DateTime startDate;
  final DateTime endDate;
  final bool ongoing;
  final bool hasReminder;
  final DateTime? reminderTime;
  final String projectId;

  @override
  List<Object?> get props => [
        title,
        description,
        estimatedPomodoros,
        startDate,
        endDate,
        ongoing,
        hasReminder,
        reminderTime,
        projectId,
      ];
}

final class UpdateTask extends TaskEvent {
  const UpdateTask({
    required this.id,
    required this.title,
    this.description,
    this.estimatedPomodoros,
    this.startDate,
    this.endDate,
    this.ongoing,
    this.hasReminder,
    this.reminderTime,
    this.projectId,
  });
  final String id;
  final String title;
  final String? description;
  final int? estimatedPomodoros;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? ongoing;
  final bool? hasReminder;
  final DateTime? reminderTime;
  final String? projectId;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        estimatedPomodoros,
        startDate,
        endDate,
        ongoing,
        hasReminder,
        reminderTime,
        projectId,
      ];
}

final class DeleteTask extends TaskEvent {
  const DeleteTask(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class MarkTaskAsInProgress extends TaskEvent {
  const MarkTaskAsInProgress(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class MarkTaskAsCompleted extends TaskEvent {
  const MarkTaskAsCompleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class IncrementTaskPomodoro extends TaskEvent {
  const IncrementTaskPomodoro(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
