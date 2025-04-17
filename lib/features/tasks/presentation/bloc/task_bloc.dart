// lib/features/tasks/presentation/bloc/task_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;
  final Uuid uuid;

  TaskBloc({
    required this.taskRepository,
    required this.uuid,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTasksByDate>(_onLoadTasksByDate);
    on<LoadTasksInRange>(_onLoadTasksInRange);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<MarkTaskAsInProgress>(_onMarkTaskAsInProgress);
    on<MarkTaskAsCompleted>(_onMarkTaskAsCompleted);
    on<IncrementTaskPomodoro>(_onIncrementTaskPomodoro);
  }

  Future<void> _onLoadTasks(
    LoadTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getAllTasks();
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
      final tasks = await taskRepository.getTasksForDate(event.date);

      // Filter by project if specified
      if (event.projectId != null) {
        final filteredTasks = tasks
            .where((task) => task.projectId == event.projectId)
            .toList();
        emit(TaskLoaded(filteredTasks));
      } else {
        emit(TaskLoaded(tasks));
      }
    } catch (e) {
      emit(TaskError('Failed to load tasks for date: $e'));
    }
  }
 Future<void> _onLoadTasksInRange(
    LoadTasksInRange event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await taskRepository.getTasksInDateRange(
        event.startDate,
        event.endDate,
      );

      // Filter by project if specified
      if (event.projectId != null) {
        final filteredTasks = tasks
            .where((task) => task.projectId == event.projectId)
            .toList();
        emit(TaskLoaded(filteredTasks));
      } else {
        emit(TaskLoaded(tasks));
      }
    } catch (e) {
      emit(TaskError('Failed to load tasks in range: $e'));
    }
  }

  Future<void> _onAddTask(
    AddTask event, 
    Emitter<TaskState> emit
  ) async {
    emit(TaskLoading());
    try {
      // Create a new task
      final now = DateTime.now().millisecondsSinceEpoch;
      final task = Task(
        id: uuid.v4(),
        title: event.title,
        description: event.description,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
        pomodorosCompleted: 0,
        estimatedPomodoros: event.estimatedPomodoros,
        startDate: event.startDate.millisecondsSinceEpoch,
        endDate: event.endDate.millisecondsSinceEpoch,
        ongoing: event.ongoing,
        hasReminder: event.hasReminder,
        reminderTime: event.reminderTime?.millisecondsSinceEpoch,
        projectId: event.projectId,
      );

      await taskRepository.saveTask(task);
      final tasks = await taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task added successfully'));
    } catch (e) {
      emit(TaskError('Failed to add task: $e'));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTask event, 
    Emitter<TaskState> emit
  ) async {
    emit(TaskLoading());
    try {
      final existingTask = await taskRepository.getTaskById(event.id);
      if (existingTask == null) {
        emit(const TaskError('Task not found'));
        return;
      }

      final updatedTask = existingTask.copyWith(
        title: event.title,
        description: event.description,
        estimatedPomodoros: event.estimatedPomodoros,
        startDate: event.startDate?.millisecondsSinceEpoch,
        endDate: event.endDate?.millisecondsSinceEpoch,
        ongoing: event.ongoing,
        hasReminder: event.hasReminder,
        reminderTime: event.reminderTime?.millisecondsSinceEpoch,
        projectId: event.projectId,
      );

      await taskRepository.saveTask(updatedTask);
      final tasks = await taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Task updated successfully'));
    } catch (e) {
      emit(TaskError('Failed to update task: $e'));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTask event, 
    Emitter<TaskState> emit
  ) async {
    emit(TaskLoading());
    try {
      await taskRepository.deleteTask(event.id);
      final tasks = await taskRepository.getAllTasks();
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
      await taskRepository.markTaskAsInProgress(event.id);
      final tasks = await taskRepository.getAllTasks();
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
      await taskRepository.markTaskAsCompleted(event.id);
      final tasks = await taskRepository.getAllTasks();
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
      await taskRepository.incrementTaskPomodoro(event.id);
      final tasks = await taskRepository.getAllTasks();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Pomodoro incremented for task'));
    } catch (e) {
      emit(TaskError('Failed to increment pomodoro: $e'));
    }
  }
}