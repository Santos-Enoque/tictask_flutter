import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'timer_state_model.g.dart';

@HiveType(typeId: 4)
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

@HiveType(typeId: 5)
enum TimerMode {
  @HiveField(0)
  focus,

  @HiveField(1)
  break_,
}

@HiveType(typeId: 3)
class TimerStateModel extends Equatable {
  const TimerStateModel({
    this.id = 'default',
    this.timeRemaining = 25 * 60, // 25 minutes by default
    this.status = TimerStatus.idle,
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.lastUpdateTime = 0,
    this.timerMode = TimerMode.focus,
  });
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int timeRemaining;

  @HiveField(2)
  final TimerStatus status;

  @HiveField(3)
  final int pomodorosCompleted;

  @HiveField(4)
  final String? currentTaskId;

  @HiveField(5)
  final int lastUpdateTime;

  @HiveField(6)
  final TimerMode timerMode;

  // Create a copy with updated fields
  TimerStateModel copyWith({
    String? id,
    int? timeRemaining,
    TimerStatus? status,
    int? pomodorosCompleted,
    String? currentTaskId,
    int? lastUpdateTime,
    TimerMode? timerMode,
  }) {
    return TimerStateModel(
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
  static const TimerStateModel defaultState = TimerStateModel();

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
