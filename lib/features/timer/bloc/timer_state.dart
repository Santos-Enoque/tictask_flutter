part of 'timer_bloc.dart';

enum TimerUIStatus {
  initial,
  running,
  paused,
  finished,
  breakReady,
  breakRunning,
}

class TimerState extends Equatable {
  final TimerUIStatus status;
  final int timeRemaining;
  final TimerConfig config;
  final int pomodorosCompleted;
  final String? currentTaskId;
  final TimerMode timerMode;
  final int todaysPomodoros;
  final double progress;

  const TimerState({
    this.status = TimerUIStatus.initial,
    this.timeRemaining = 25 * 60, // Default is 25 minutes
    this.config = const TimerConfig(),
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.timerMode = TimerMode.focus,
    this.todaysPomodoros = 0,
    this.progress = 0,
  });

  TimerState copyWith({
    TimerUIStatus? status,
    int? timeRemaining,
    TimerConfig? config,
    int? pomodorosCompleted,
    String? currentTaskId,
    TimerMode? timerMode,
    int? todaysPomodoros,
    double? progress,
  }) {
    return TimerState(
      status: status ?? this.status,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      config: config ?? this.config,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      timerMode: timerMode ?? this.timerMode,
      todaysPomodoros: todaysPomodoros ?? this.todaysPomodoros,
      progress: progress ?? this.progress,
    );
  }

  // Helper method to calculate progress
  static double calculateProgress({
    required int timeRemaining,
    required int totalDuration,
  }) {
    if (totalDuration <= 0) return 0;
    final elapsed = totalDuration - timeRemaining;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  // Factory method to create state from model
  factory TimerState.fromModel({
    required TimerStateModel model,
    required TimerConfig config,
    required int todaysPomodoros,
  }) {
    TimerUIStatus status;
    
    switch (model.status) {
      case TimerStatus.idle:
        status = TimerUIStatus.initial;
        break;
      case TimerStatus.running:
        status = TimerUIStatus.running;
        break;
      case TimerStatus.paused:
        status = TimerUIStatus.paused;
        break;
      case TimerStatus.break_:
        status = TimerUIStatus.breakReady;
        break;
    }

    // Calculate total duration based on timer mode
    final totalDuration = model.timerMode == TimerMode.focus
        ? config.pomoDuration
        : model.pomodorosCompleted % config.longBreakInterval == 0
            ? config.longBreakDuration
            : config.shortBreakDuration;

    // Calculate progress
    final progress = calculateProgress(
      timeRemaining: model.timeRemaining,
      totalDuration: totalDuration,
    );

    return TimerState(
      status: status,
      timeRemaining: model.timeRemaining,
      config: config,
      pomodorosCompleted: model.pomodorosCompleted,
      currentTaskId: model.currentTaskId,
      timerMode: model.timerMode,
      todaysPomodoros: todaysPomodoros,
      progress: progress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        timeRemaining,
        config,
        pomodorosCompleted,
        currentTaskId,
        timerMode,
        todaysPomodoros,
        progress,
      ];
}