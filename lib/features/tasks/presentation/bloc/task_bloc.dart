// lib/features/tasks/presentation/bloc/task_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/features/tasks/domain/usecases/increment_task_pmodoro_use_case.dart';
import 'package:uuid/uuid.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_all_tasks_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_by_project_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_for_date_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/get_tasks_in_date_range_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/mark_task_as_completed_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/mark_task_as_in_progress_use_case.dart';
import 'package:tictask/features/tasks/domain/usecases/update_task_use_case.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetAllTasksUseCase _getAllTasksUseCase;
  final GetTasksForDateUseCase _getTasksForDateUseCase;
  final GetTasksInDateRangeUseCase _getTasksInDateRangeUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final MarkTaskAsInProgressUseCase _markTaskAsInProgressUseCase;
  final MarkTaskAsCompletedUseCase _markTaskAsCompletedUseCase;
  final IncrementTaskPomodoroUseCase _incrementTaskPomodoroUseCase;
  final GetTasksByProjectUseCase _getTasksByProjectUseCase;

  TaskBloc({
    required GetAllTasksUseCase getAllTasksUseCase,
    required GetTasksForDateUseCase getTasksForDateUseCase,
    required GetTasksInDateRangeUseCase getTasksInDateRangeUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required MarkTaskAsInProgressUseCase markTaskAsInProgressUseCase,
    required MarkTaskAsCompletedUseCase markTaskAsCompletedUseCase,
    required IncrementTaskPomodoroUseCase incrementTaskPomodoroUseCase,
    required GetTasksByProjectUseCase getTasksByProjectUseCase,
  })  : _getAllTasksUseCase = getAllTasksUseCase,
        _getTasksForDateUseCase = getTasksForDateUseCase,
        _getTasksInDateRangeUseCase = getTasksInDateRangeUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _markTaskAsInProgressUseCase = markTaskAsInProgressUseCase,
        _markTaskAsCompletedUseCase = markTaskAsCompletedUseCase,
        _incrementTaskPomodoroUseCase = incrementTaskPomodoroUseCase,
        _getTasksByProjectUseCase = getTasksByProjectUseCase,
        super(TaskInitial()) {
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
      final tasks = await _getAllTasksUseCase.execute();
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
      final tasks = await _getTasksForDateUseCase.execute(
        event.date,
        projectId: event.projectId,
      );
      emit(TaskLoaded(tasks));
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
      final tasks = await _getTasksInDateRangeUseCase.execute(
        event.startDate,
        event.endDate,
        projectId: event.projectId,
      );
      emit(TaskLoaded(tasks));
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
      await _createTaskUseCase.execute(
        title: event.title,
        description: event.description,
        estimatedPomodoros: event.estimatedPomodoros,
        startDate: event.startDate,
        endDate: event.endDate,
        ongoing: event.ongoing,
        hasReminder: event.hasReminder,
        reminderTime: event.reminderTime,
        projectId: event.projectId,
      );
      
      final tasks = await _getAllTasksUseCase.execute();
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
      await _updateTaskUseCase.execute(
        id: event.id,
        title: event.title,
        description: event.description,
        estimatedPomodoros: event.estimatedPomodoros,
        startDate: event.startDate,
        endDate: event.endDate,
        ongoing: event.ongoing,
        hasReminder: event.hasReminder,
        reminderTime: event.reminderTime,
        projectId: event.projectId,
      );

      final tasks = await _getAllTasksUseCase.execute();
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
      await _deleteTaskUseCase.execute(event.id);
      
      final tasks = await _getAllTasksUseCase.execute();
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
      await _markTaskAsInProgressUseCase.execute(event.id);
      
      final tasks = await _getAllTasksUseCase.execute();
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
      await _markTaskAsCompletedUseCase.execute(event.id);
      
      final tasks = await _getAllTasksUseCase.execute();
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
      await _incrementTaskPomodoroUseCase.execute(event.id);
      
      final tasks = await _getAllTasksUseCase.execute();
      emit(TaskLoaded(tasks));
      emit(const TaskActionSuccess('Pomodoro incremented for task'));
    } catch (e) {
      emit(TaskError('Failed to increment pomodoro: $e'));
    }
  }
}
