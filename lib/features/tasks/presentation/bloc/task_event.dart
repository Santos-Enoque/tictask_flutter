// lib/features/tasks/presentation/bloc/task_event.dart
part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  const LoadTasks();
}

class LoadTasksByDate extends TaskEvent {
  final DateTime date;
  final String? projectId;
  
  const LoadTasksByDate(this.date, {this.projectId});
  
  @override
  List<Object?> get props => [date, projectId];
}

class LoadTasksInRange extends TaskEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? projectId;
  
  const LoadTasksInRange(this.startDate, this.endDate, {this.projectId});
  
  @override
  List<Object?> get props => [startDate, endDate, projectId];
}

class AddTask extends TaskEvent {
  final String title;
  final String? description;
  final int? estimatedPomodoros;
  final DateTime startDate;
  final DateTime endDate;
  final bool ongoing;
  final bool hasReminder;
  final DateTime? reminderTime;
  final String projectId;
  
  const AddTask({
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.estimatedPomodoros,
    this.ongoing = false,
    this.hasReminder = false,
    this.reminderTime,
    this.projectId = 'inbox',
  });
  
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

class UpdateTask extends TaskEvent {
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

class DeleteTask extends TaskEvent {
  final String id;
  
  const DeleteTask(this.id);
  
  @override
  List<Object?> get props => [id];
}

class MarkTaskAsInProgress extends TaskEvent {
  final String id;
  
  const MarkTaskAsInProgress(this.id);
  
  @override
  List<Object?> get props => [id];
}

class MarkTaskAsCompleted extends TaskEvent {
  final String id;
  
  const MarkTaskAsCompleted(this.id);
  
  @override
  List<Object?> get props => [id];
}

class IncrementTaskPomodoro extends TaskEvent {
  final String id;
  
  const IncrementTaskPomodoro(this.id);
  
  @override
  List<Object?> get props => [id];
}
