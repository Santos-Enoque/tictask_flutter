import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'timer_entity.g.dart';

/// Timer mode to indicate the current mode of the timer
@HiveType(typeId: 4)
enum TimerMode {
  @HiveField(0)
  focus,
  @HiveField(1)
  break_,
}

/// Timer status to track the current state of the timer
@HiveType(typeId: 5)
enum TimerStatus {
  @HiveField(0)
  idle,
  @HiveField(1)
  running,
  @HiveField(2)
  paused,
  @HiveField(3)
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
