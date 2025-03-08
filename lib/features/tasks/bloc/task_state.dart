part of 'task_bloc.dart';

sealed class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object> get props => [];
}

final class TaskInitial extends TaskState {}

final class TaskLoading extends TaskState {}

final class TaskLoaded extends TaskState {
  const TaskLoaded(this.tasks);
  final List<Task> tasks;

  @override
  List<Object> get props => [tasks];
}

final class TaskError extends TaskState {
  const TaskError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

final class TaskActionSuccess extends TaskState {
  const TaskActionSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
