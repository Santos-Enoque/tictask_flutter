import 'package:equatable/equatable.dart';

enum TimerStatus {
  idle,
  running,
  paused,
  break_,
}

enum TimerMode {
  focus,
  break_,
}

class TimerState extends Equatable {
  final String id;
  final int timeRemaining;
  final TimerStatus status;
  final int pomodorosCompleted;
  final String? currentTaskId;
  final int lastUpdateTime;
  final TimerMode timerMode;

  const TimerState({
    this.id = 'default',
    this.timeRemaining = 25 * 60, // 25 minutes by default
    this.status = TimerStatus.idle,
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.lastUpdateTime = 0,
    this.timerMode = TimerMode.focus,
  });

  TimerState copyWith({
    String? id,
    int? timeRemaining,
    TimerStatus? status,
    int? pomodorosCompleted,
    String? currentTaskId,
    int? lastUpdateTime,
    TimerMode? timerMode,
  }) {
    return TimerState(
      id: id ?? this.id,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      status: status ?? this.status,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      timerMode: timerMode ?? this.timerMode,
    );
  }

  // Default state
  static const TimerState defaultState = TimerState();

  @override
  List<Object?> get props => [
        id,
        timeRemaining,
        status,
        pomodorosCompleted,
        currentTaskId,
        lastUpdateTime,
        timerMode,
      ];
}
