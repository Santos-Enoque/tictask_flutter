// lib/features/timer/presentation/bloc/timer_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/core/services/notification_service.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/usecases/get_completed_pomodoro_count_today_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_timer_config_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_timer_state_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/get_total_completed_pomodoros_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/save_session_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/save_timer_config_use_case.dart';
import 'package:tictask/features/timer/domain/usecases/update_timer_state_use_case.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  // Use cases
  final GetTimerConfigUseCase _getTimerConfigUseCase;
  final SaveTimerConfigUseCase _saveTimerConfigUseCase;
  final GetTimerStateUseCase _getTimerStateUseCase;
  final UpdateTimerStateUseCase _updateTimerStateUseCase;
  final SaveSessionUseCase _saveSessionUseCase;
  final GetCompletedPomodoroCountTodayUseCase
      _getCompletedPomodoroCountTodayUseCase;
  final GetTotalCompletedPomodorosUseCase _getTotalCompletedPomodorosUseCase;

  // Services
  final NotificationService _notificationService;
  final ITaskRepository? _taskRepository;

  // Timer for ticking
  Timer? _timer;

  TimerBloc({
    required GetTimerConfigUseCase getTimerConfigUseCase,
    required SaveTimerConfigUseCase saveTimerConfigUseCase,
    required GetTimerStateUseCase getTimerStateUseCase,
    required UpdateTimerStateUseCase updateTimerStateUseCase,
    required SaveSessionUseCase saveSessionUseCase,
    required GetCompletedPomodoroCountTodayUseCase
        getCompletedPomodoroCountTodayUseCase,
    required GetTotalCompletedPomodorosUseCase
        getTotalCompletedPomodorosUseCase,
    required NotificationService notificationService,
    ITaskRepository? taskRepository,
  })  : _getTimerConfigUseCase = getTimerConfigUseCase,
        _saveTimerConfigUseCase = saveTimerConfigUseCase,
        _getTimerStateUseCase = getTimerStateUseCase,
        _updateTimerStateUseCase = updateTimerStateUseCase,
        _saveSessionUseCase = saveSessionUseCase,
        _getCompletedPomodoroCountTodayUseCase =
            getCompletedPomodoroCountTodayUseCase,
        _getTotalCompletedPomodorosUseCase = getTotalCompletedPomodorosUseCase,
        _notificationService = notificationService,
        _taskRepository = taskRepository,
        super(const TimerState()) {
    on<TimerInitialized>(_onTimerInitialized);
    on<TimerStarted>(_onTimerStarted);
    on<TimerPaused>(_onTimerPaused);
    on<TimerResumed>(_onTimerResumed);
    on<TimerReset>(_onTimerReset);
    on<TimerTicked>(_onTimerTicked);
    on<TimerConfigChanged>(_onTimerConfigChanged);
    on<TimerBreakStarted>(_onTimerBreakStarted);
    on<TimerBreakSkipped>(_onTimerBreakSkipped);
    on<TimerCompleted>(_onTimerCompleted);
  }

  Future<void> _onTimerInitialized(
      TimerInitialized event, Emitter<TimerState> emit) async {
    try {
      // Load timer config
      final config = await _getTimerConfigUseCase.execute();

      // Load timer state
      final timerEntity = await _getTimerStateUseCase.execute();

      // Get today's pomodoros count
      final todaysPomodoros =
          await _getCompletedPomodoroCountTodayUseCase.execute();

      // Calculate timer duration and status
      final newState = TimerState.fromEntity(
        entity: timerEntity,
        config: config,
        todaysPomodoros: todaysPomodoros,
      );

      emit(newState);

      // If timer was running (app restart scenario), resume it
      if (timerEntity.status == TimerStatus.running) {
        add(const TimerResumed());
      }
    } catch (e) {
      // Handle initialization error
      emit(state.copyWith(status: TimerUIStatus.initial));
    }
  }

  Future<void> _onTimerStarted(
      TimerStarted event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.initial ||
        state.status == TimerUIStatus.paused) {
      // Update task association if provided
      final taskId = event.taskId ?? state.currentTaskId;

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.running,
        timeRemaining: currentTimerEntity.timeRemaining,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: taskId,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      // Start the timer
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) => add(TimerTicked(duration: state.timeRemaining - 1)),
      );

      emit(state.copyWith(
        status: TimerUIStatus.running,
        currentTaskId: taskId,
      ));
    }
  }

  Future<void> _onTimerPaused(
      TimerPaused event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.running ||
        state.status == TimerUIStatus.breakRunning) {
      _timer?.cancel();

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.paused,
        timeRemaining: currentTimerEntity.timeRemaining,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      emit(state.copyWith(status: TimerUIStatus.paused));
    }
  }

  Future<void> _onTimerResumed(
      TimerResumed event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.paused) {
      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.running,
        timeRemaining: currentTimerEntity.timeRemaining,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      // Start the timer
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) => add(TimerTicked(duration: state.timeRemaining - 1)),
      );

      final newStatus = state.timerMode == TimerMode.focus
          ? TimerUIStatus.running
          : TimerUIStatus.breakRunning;

      emit(state.copyWith(status: newStatus));
    }
  }

  Future<void> _onTimerReset(TimerReset event, Emitter<TimerState> emit) async {
    _timer?.cancel();

    // Reset to initial state with focus timer duration
    int resetDuration;
    final config = await _getTimerConfigUseCase.execute();

    if (state.timerMode == TimerMode.focus) {
      resetDuration = config.pomoDuration;
    } else {
      // If in break mode, determine which break type
      resetDuration = (state.pomodorosCompleted % config.longBreakInterval == 0)
          ? config.longBreakDuration
          : config.shortBreakDuration;
    }

    // Update timer state in repository
    final currentTimerEntity = await _getTimerStateUseCase.execute();
    final updatedTimerEntity = TimerEntity(
      id: currentTimerEntity.id,
      status: TimerStatus.idle,
      timeRemaining: resetDuration,
      pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
      currentTaskId: null,
      lastUpdateTime: currentTimerEntity.lastUpdateTime,
      timerMode: currentTimerEntity.timerMode,
    );

    await _updateTimerStateUseCase.execute(updatedTimerEntity);

    emit(state.copyWith(
      status: TimerUIStatus.initial,
      timeRemaining: resetDuration,
      currentTaskId: null,
      progress: 0,
    ));
  }

  Future<void> _onTimerTicked(
      TimerTicked event, Emitter<TimerState> emit) async {
    if (event.duration > 0) {
      // Calculate progress based on timer mode
      final config = await _getTimerConfigUseCase.execute();
      final totalDuration = state.timerMode == TimerMode.focus
          ? config.pomoDuration
          : state.pomodorosCompleted % config.longBreakInterval == 0
              ? config.longBreakDuration
              : config.shortBreakDuration;

      final progress = TimerState.calculateProgress(
        timeRemaining: event.duration,
        totalDuration: totalDuration,
      );

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: currentTimerEntity.status,
        timeRemaining: event.duration,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      emit(state.copyWith(
        timeRemaining: event.duration,
        progress: progress,
      ));
    } else {
      // Timer completed
      add(const TimerCompleted());
    }
  }

  Future<void> _onTimerConfigChanged(
      TimerConfigChanged event, Emitter<TimerState> emit) async {
    await _saveTimerConfigUseCase.execute(event.config);

    // If timer is idle, update the remaining time to match new duration
    if (state.status == TimerUIStatus.initial) {
      // Determine which duration to use based on timer mode
      int newDuration;
      if (state.timerMode == TimerMode.focus) {
        newDuration = event.config.pomoDuration;
      } else {
        // If in break mode, determine which break type
        newDuration =
            state.pomodorosCompleted % event.config.longBreakInterval == 0
                ? event.config.longBreakDuration
                : event.config.shortBreakDuration;
      }

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: currentTimerEntity.status,
        timeRemaining: newDuration,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      emit(state.copyWith(
        config: event.config,
        timeRemaining: newDuration,
        progress: 0,
      ));
    } else {
      // For active timers, adjust the remaining time proportionally
      final oldDuration = state.timerMode == TimerMode.focus
          ? state.config.pomoDuration
          : state.pomodorosCompleted % state.config.longBreakInterval == 0
              ? state.config.longBreakDuration
              : state.config.shortBreakDuration;

      // Get new duration based on timer mode
      final newDuration = state.timerMode == TimerMode.focus
          ? event.config.pomoDuration
          : state.pomodorosCompleted % event.config.longBreakInterval == 0
              ? event.config.longBreakDuration
              : event.config.shortBreakDuration;

      // Calculate remaining time as a percentage and apply to new duration
      final remainingPercentage = state.timeRemaining / oldDuration;
      final adjustedTimeRemaining = (remainingPercentage * newDuration).round();

      // Calculate new progress
      final progress = TimerState.calculateProgress(
        timeRemaining: adjustedTimeRemaining,
        totalDuration: newDuration,
      );

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: currentTimerEntity.status,
        timeRemaining: adjustedTimeRemaining,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: currentTimerEntity.timerMode,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      emit(state.copyWith(
        config: event.config,
        timeRemaining: adjustedTimeRemaining,
        progress: progress,
      ));
    }
  }

  Future<void> _onTimerBreakStarted(
      TimerBreakStarted event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.breakReady) {
      // Start break timer
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) => add(TimerTicked(duration: state.timeRemaining - 1)),
      );

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.running,
        timeRemaining: currentTimerEntity.timeRemaining,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
        timerMode: TimerMode.break_,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      // Notify break started
      final config = await _getTimerConfigUseCase.execute();
      final isLongBreak =
          state.pomodorosCompleted % config.longBreakInterval == 0;
      final breakType = isLongBreak ? 'Long Break' : 'Short Break';
      final breakDuration =
          isLongBreak ? config.longBreakDuration : config.shortBreakDuration;

      await _notificationService.showBreakNotification(
        title: '$breakType Started',
        body: 'Time for a $breakDuration second break!',
        isBreakStart: true,
      );

      emit(state.copyWith(
        status: TimerUIStatus.breakRunning,
        timerMode: TimerMode.break_,
      ));
    }
  }

  Future<void> _onTimerBreakSkipped(
      TimerBreakSkipped event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.breakReady ||
        state.status == TimerUIStatus.breakRunning) {
      _timer?.cancel();

      final config = await _getTimerConfigUseCase.execute();

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.idle,
        timeRemaining: config.pomoDuration,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: null,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: TimerMode.focus,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      // Cancel any break notifications
      await _notificationService.cancelAllNotifications();

      emit(state.copyWith(
        status: TimerUIStatus.initial,
        timeRemaining: config.pomoDuration,
        timerMode: TimerMode.focus,
        currentTaskId: null,
        progress: 0,
      ));
    }
  }

  Future<void> _onTimerCompleted(
      TimerCompleted event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    final config = await _getTimerConfigUseCase.execute();

    // Handle timer completion based on mode
    if (state.timerMode == TimerMode.focus) {
      // Complete focus session
      final pomodorosCompleted = state.pomodorosCompleted + 1;

      // Save the completed session
      final session = TimerSessionModel.completed(
        startTime:
            DateTime.now().millisecondsSinceEpoch - config.pomoDuration * 1000,
        endTime: DateTime.now().millisecondsSinceEpoch,
        duration: config.pomoDuration,
        type: SessionType.pomodoro,
        taskId: state.currentTaskId,
      );

      await _saveSessionUseCase.execute(session);

      // Calculate break duration
      final isLongBreak = pomodorosCompleted % config.longBreakInterval == 0;
      final breakDuration =
          isLongBreak ? config.longBreakDuration : config.shortBreakDuration;

      // Update timer state in repository
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.break_,
        timeRemaining: breakDuration,
        pomodorosCompleted: pomodorosCompleted,
        currentTaskId: currentTimerEntity.currentTaskId,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: TimerMode.break_,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      // Get updated today's pomodoros
      final todaysPomodoros =
          await _getCompletedPomodoroCountTodayUseCase.execute();

      // Show pomodoro completion notification
      String taskName = "your task";
      if (state.currentTaskId != null && _taskRepository != null) {
        try {
          final task = await _taskRepository!.getTaskById(state.currentTaskId!);
          if (task != null) {
            taskName = task.title;
          }
        } catch (e) {
          // Fallback to generic task name
        }
      }

      await _notificationService.showTimerCompletedNotification(
        title: 'Pomodoro Completed!',
        body:
            'You\'ve completed a pomodoro session${state.currentTaskId != null ? ' for $taskName' : ''}.',
        payload: 'pomodoro_completed',
      );

      emit(state.copyWith(
        status: TimerUIStatus.breakReady,
        timeRemaining: breakDuration,
        pomodorosCompleted: pomodorosCompleted,
        timerMode: TimerMode.break_,
        todaysPomodoros: todaysPomodoros,
        progress: 0,
      ));
    } else {
      // Complete break session
      final isLongBreak =
          state.pomodorosCompleted % config.longBreakInterval == 0;

      // Save break session
      final session = TimerSessionModel.completed(
        startTime: DateTime.now().millisecondsSinceEpoch -
            (isLongBreak
                    ? config.longBreakDuration
                    : config.shortBreakDuration) *
                1000,
        endTime: DateTime.now().millisecondsSinceEpoch,
        duration:
            isLongBreak ? config.longBreakDuration : config.shortBreakDuration,
        type: isLongBreak ? SessionType.longBreak : SessionType.shortBreak,
        taskId: null,
      );

      await _saveSessionUseCase.execute(session);

      // Show break completed notification
      await _notificationService.showBreakNotification(
        title: 'Break Completed',
        body: 'Time to get back to work! Ready for your next pomodoro?',
        isBreakStart: false,
      );

      // Reset to focus timer
      final currentTimerEntity = await _getTimerStateUseCase.execute();
      final updatedTimerEntity = TimerEntity(
        id: currentTimerEntity.id,
        status: TimerStatus.idle,
        timeRemaining: config.pomoDuration,
        pomodorosCompleted: currentTimerEntity.pomodorosCompleted,
        currentTaskId: null,
        lastUpdateTime: currentTimerEntity.lastUpdateTime,
        timerMode: TimerMode.focus,
      );

      await _updateTimerStateUseCase.execute(updatedTimerEntity);

      emit(state.copyWith(
        status: TimerUIStatus.initial,
        timeRemaining: config.pomoDuration,
        timerMode: TimerMode.focus,
        currentTaskId: null,
        progress: 0,
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
