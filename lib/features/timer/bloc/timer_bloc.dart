import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

part 'timer_event.dart';
part 'timer_state.dart';


class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final TimerRepository _timerRepository;
  Timer? _timer;

  TimerBloc({required TimerRepository timerRepository})
      : _timerRepository = timerRepository,
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
      final config = await _timerRepository.getTimerConfig();
      
      // Load timer state
      final timerModel = await _timerRepository.getTimerState();
      
      // Get today's pomodoros count
      final todaysPomodoros = await _timerRepository.getCompletedPomodoroCountToday();

      // Calculate timer duration and status
      final newState = TimerState.fromModel(
        model: timerModel,
        config: config,
        todaysPomodoros: todaysPomodoros,
      );
      
      emit(newState);
      
      // If timer was running (app restart scenario), resume it
      if (timerModel.status == TimerStatus.running) {
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
      TimerStateModel timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.running,
            currentTaskId: taskId,
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
      
      await _timerRepository.updateTimerState(timerModel);

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
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(status: TimerStatus.paused);
      
      await _timerRepository.updateTimerState(timerModel);

      emit(state.copyWith(status: TimerUIStatus.paused));
    }
  }

  Future<void> _onTimerResumed(
      TimerResumed event, Emitter<TimerState> emit) async {
    if (state.status == TimerUIStatus.paused) {
      // Update timer state in repository
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.running,
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
      
      await _timerRepository.updateTimerState(timerModel);

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

  Future<void> _onTimerReset(
      TimerReset event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    
    // Reset to initial state with focus timer duration
    int resetDuration;
    
    if (state.timerMode == TimerMode.focus) {
      resetDuration = state.config.pomoDuration;
    } else {
      // If in break mode, determine which break type
      resetDuration = (state.pomodorosCompleted % state.config.longBreakInterval == 0)
          ? state.config.longBreakDuration
          : state.config.shortBreakDuration;
    }

    // Update timer state in repository
    final timerModel = (await _timerRepository.getTimerState())
        .copyWith(
          status: TimerStatus.idle,
          timeRemaining: resetDuration,
          currentTaskId: null,
        );
    
    await _timerRepository.updateTimerState(timerModel);

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
      final totalDuration = state.timerMode == TimerMode.focus
          ? state.config.pomoDuration
          : state.pomodorosCompleted % state.config.longBreakInterval == 0
              ? state.config.longBreakDuration
              : state.config.shortBreakDuration;
              
      final progress = TimerState.calculateProgress(
        timeRemaining: event.duration,
        totalDuration: totalDuration,
      );
      
      // Update timer state in repository
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            timeRemaining: event.duration,
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
      
      await _timerRepository.updateTimerState(timerModel);

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
    await _timerRepository.saveTimerConfig(event.config);
    
    // If timer is idle, update the remaining time to match new duration
    if (state.status == TimerUIStatus.initial) {
      // Determine which duration to use based on timer mode
      int newDuration;
      if (state.timerMode == TimerMode.focus) {
        newDuration = event.config.pomoDuration;
      } else {
        // If in break mode, determine which break type
        newDuration = state.pomodorosCompleted % event.config.longBreakInterval == 0
            ? event.config.longBreakDuration
            : event.config.shortBreakDuration;
      }
      
      // Update timer state in repository
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(timeRemaining: newDuration);
      
      await _timerRepository.updateTimerState(timerModel);

      emit(state.copyWith(
        config: event.config,
        timeRemaining: newDuration,
        progress: 0,
      ));
    } else {
      // For active timers, adjust the remaining time proportionally
      // Get current duration based on timer mode
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
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(timeRemaining: adjustedTimeRemaining);
      
      await _timerRepository.updateTimerState(timerModel);

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
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.running,
            timerMode: TimerMode.break_,
            lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
          );
      
      await _timerRepository.updateTimerState(timerModel);

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
      
      // Update timer state in repository
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.idle,
            timeRemaining: state.config.pomoDuration,
            timerMode: TimerMode.focus,
            currentTaskId: null,
          );
      
      await _timerRepository.updateTimerState(timerModel);

      emit(state.copyWith(
        status: TimerUIStatus.initial,
        timeRemaining: state.config.pomoDuration,
        timerMode: TimerMode.focus,
        currentTaskId: null,
        progress: 0,
      ));
    }
  }

  Future<void> _onTimerCompleted(
      TimerCompleted event, Emitter<TimerState> emit) async {
    _timer?.cancel();
    
    // Handle timer completion based on mode
    if (state.timerMode == TimerMode.focus) {
      // Complete focus session
      final pomodorosCompleted = state.pomodorosCompleted + 1;
      
      // Save the completed session
      final session = TimerSession.completed(
        startTime: DateTime.now().millisecondsSinceEpoch - state.config.pomoDuration * 1000,
        endTime: DateTime.now().millisecondsSinceEpoch,
        duration: state.config.pomoDuration,
        type: SessionType.pomodoro,
        taskId: state.currentTaskId,
      );
      
      await _timerRepository.saveSession(session);
      
      // Calculate break duration
      final isLongBreak = pomodorosCompleted % state.config.longBreakInterval == 0;
      final breakDuration = isLongBreak
          ? state.config.longBreakDuration
          : state.config.shortBreakDuration;
      
      // Update timer state in repository for break
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.break_,
            timeRemaining: breakDuration,
            pomodorosCompleted: pomodorosCompleted,
            timerMode: TimerMode.break_,
          );
      
      await _timerRepository.updateTimerState(timerModel);
      
      // Get updated today's pomodoros
      final todaysPomodoros = await _timerRepository.getCompletedPomodoroCountToday();

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
      final isLongBreak = state.pomodorosCompleted % state.config.longBreakInterval == 0;
      
      // Save break session
      final session = TimerSession.completed(
        startTime: DateTime.now().millisecondsSinceEpoch - 
            (isLongBreak ? state.config.longBreakDuration : state.config.shortBreakDuration) * 1000,
        endTime: DateTime.now().millisecondsSinceEpoch,
        duration: isLongBreak ? state.config.longBreakDuration : state.config.shortBreakDuration,
        type: isLongBreak ? SessionType.longBreak : SessionType.shortBreak,
        taskId: null,
      );
      
      await _timerRepository.saveSession(session);
      
      // Reset to focus timer
      final timerModel = (await _timerRepository.getTimerState())
          .copyWith(
            status: TimerStatus.idle,
            timeRemaining: state.config.pomoDuration,
            timerMode: TimerMode.focus,
            currentTaskId: null,
          );
      
      await _timerRepository.updateTimerState(timerModel);

      emit(state.copyWith(
        status: TimerUIStatus.initial,
        timeRemaining: state.config.pomoDuration,
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