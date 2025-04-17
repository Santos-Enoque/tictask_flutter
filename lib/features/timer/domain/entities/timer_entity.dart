import 'package:equatable/equatable.dart';

/// Timer mode to indicate the current mode of the timer
enum TimerMode {
  focus,
  break_,
}

/// Timer status to track the current state of the timer
enum TimerStatus {
  idle,
  running,
  paused,
  break_,
}

/// Entity class for timer state
class TimerEntity extends Equatable {
  final String id;
  final int timeRemaining;
  final TimerStatus status;
  final int pomodorosCompleted;
  final String? currentTaskId;
  final int lastUpdateTime;
  final TimerMode timerMode;

  const TimerEntity({
    this.id = 'default',
    this.timeRemaining = 25 * 60, // 25 minutes by default
    this.status = TimerStatus.idle,
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.lastUpdateTime = 0,
    this.timerMode = TimerMode.focus,
  });

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
