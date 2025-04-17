import 'package:hive/hive.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';

part 'timer_state_model.g.dart';

@HiveType(typeId: 3)
class TimerStateModel extends TimerEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final int timeRemaining;

  @HiveField(2)
  @override
  final TimerStatus status;

  @HiveField(3)
  @override
  final int pomodorosCompleted;

  @HiveField(4)
  @override
  final String? currentTaskId;

  @HiveField(5)
  @override
  final int lastUpdateTime;

  @HiveField(6)
  @override
  final TimerMode timerMode;

  const TimerStateModel({
    this.id = 'default',
    this.timeRemaining = 25 * 60, // 25 minutes by default
    this.status = TimerStatus.idle,
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.lastUpdateTime = 0,
    this.timerMode = TimerMode.focus,
  }) : super(
          id: id,
          timeRemaining: timeRemaining,
          status: status,
          pomodorosCompleted: pomodorosCompleted,
          currentTaskId: currentTaskId,
          lastUpdateTime: lastUpdateTime,
          timerMode: timerMode,
        );

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

  // Factory to create from domain entity
  factory TimerStateModel.fromEntity(TimerEntity entity) {
    return TimerStateModel(
      id: entity.id,
      timeRemaining: entity.timeRemaining,
      status: entity.status,
      pomodorosCompleted: entity.pomodorosCompleted,
      currentTaskId: entity.currentTaskId,
      lastUpdateTime: entity.lastUpdateTime,
      timerMode: entity.timerMode,
    );
  }
}
