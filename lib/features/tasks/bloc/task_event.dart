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

final class AddTask extends TaskEvent {
  const AddTask({
    required this.title,
    required this.dueDate,
    required this.ongoing,
    this.description,
    this.estimatedPomodoros,
  });
  final String title;
  final String? description;
  final int? estimatedPomodoros;
  final DateTime dueDate;
  final bool ongoing;

  @override
  List<Object?> get props =>
      [title, description, estimatedPomodoros, dueDate, ongoing];
}

final class UpdateTask extends TaskEvent {
  const UpdateTask({
    required this.id,
    this.title,
    this.description,
    this.estimatedPomodoros,
    this.dueDate,
    this.ongoing,
  });
  final String id;
  final String? title;
  final String? description;
  final int? estimatedPomodoros;
  final DateTime? dueDate;
  final bool? ongoing;

  @override
  List<Object?> get props =>
      [id, title, description, estimatedPomodoros, dueDate, ongoing];
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
