import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksByDate>(_onLoadTasksByDate);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<MarkTaskAsInProgress>(_onMarkTaskAsInProgress);
    on<MarkTaskAsCompleted>(_onMarkTaskAsCompleted);
    on<IncrementTaskPomodoro>(_onIncrementTaskPomodoro);
  }

  final TaskRepository _taskRepository;

  // Expose repository for direct access when needed
  TaskRepository get repository => _taskRepository;

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError('Failed to load tasks: $e'));
    }
  }

  Future<void> _onLoadTasksByDate(
    LoadTasksByDate event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await _taskRepository.getTasksForDate(event.date);
      emit(TaskLoaded(tasks));
    } catch (e) {
      emit(TaskError('Failed to load tasks for date: $e'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final task = Task.create(
        title: event.title,
        description: event.description,
        estimatedPomodoros: event.estimatedPomodoros,
        dueDate: event.dueDate.millisecondsSinceEpoch,
        ongoing: event.ongoing,
      );
      await _taskRepository.saveTask(task);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task added successfully'));
    } catch (e) {
      emit(TaskError('Failed to add task: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final existingTask = await _taskRepository.getTaskById(event.id);
      if (existingTask == null) {
        emit(const TaskError('Task not found'));
        return;
      }

      final updatedTask = existingTask.copyWith(
        title: event.title,
        description: event.description,
        estimatedPomodoros: event.estimatedPomodoros,
        dueDate: event.dueDate?.millisecondsSinceEpoch,
        ongoing: event.ongoing,
      );

      await _taskRepository.saveTask(updatedTask);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task updated successfully'));
    } catch (e) {
      emit(TaskError('Failed to update task: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      await _taskRepository.deleteTask(event.id);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task deleted successfully'));
    } catch (e) {
      emit(TaskError('Failed to delete task: $e'));
    }
  }

  Future<void> _onMarkTaskAsInProgress(
    MarkTaskAsInProgress event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await _taskRepository.markTaskAsInProgress(event.id);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task marked as in progress'));
    } catch (e) {
      emit(TaskError('Failed to update task status: $e'));
    }
  }

  Future<void> _onMarkTaskAsCompleted(
    MarkTaskAsCompleted event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await _taskRepository.markTaskAsCompleted(event.id);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task marked as completed'));
    } catch (e) {
      emit(TaskError('Failed to complete task: $e'));
    }
  }

  Future<void> _onIncrementTaskPomodoro(
    IncrementTaskPomodoro event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      await _taskRepository.incrementTaskPomodoro(event.id);
      final tasks = await _taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Pomodoro incremented for task'));
    } catch (e) {
      emit(TaskError('Failed to increment pomodoro: $e'));
    }
  }
}
