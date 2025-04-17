import 'package:hive/hive.dart';
import 'package:tictask/features/timer/domain/entities/timer_state.dart';

part 'timer_state_model.g.dart';

@HiveType(typeId: 4)
enum TimerStatusModel {
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
enum TimerModeModel {
  @HiveField(0)
  focus,

  @HiveField(1)
  break_,
}

@HiveType(typeId: 3)
class TimerStateModel extends TimerState {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final int timeRemaining;

  @HiveField(2)
  final TimerStatusModel statusModel;

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
  final TimerModeModel timerModeModel;

  TimerStateModel({
    this.id = 'default',
    this.timeRemaining = 25 * 60,
    this.statusModel = TimerStatusModel.idle,
    this.pomodorosCompleted = 0,
    this.currentTaskId,
    this.lastUpdateTime = 0,
    this.timerModeModel = TimerModeModel.focus,
  }) : super(
          id: id,
          timeRemaining: timeRemaining,
          status: _mapStatusModelToDomain(statusModel),
          pomodorosCompleted: pomodorosCompleted,
          currentTaskId: currentTaskId,
          lastUpdateTime: lastUpdateTime,
          timerMode: _mapModeModelToDomain(timerModeModel),
        );

  // Map status model to domain
  static TimerStatus _mapStatusModelToDomain(TimerStatusModel statusModel) {
    switch (statusModel) {
      case TimerStatusModel.idle:
        return TimerStatus.idle;
      case TimerStatusModel.running:
        return TimerStatus.running;
      case TimerStatusModel.paused:
        return TimerStatus.paused;
      case TimerStatusModel.break_:
        return TimerStatus.break_;
    }
  }

  // Map mode model to domain
  static TimerMode _mapModeModelToDomain(TimerModeModel modeModel) {
    switch (modeModel) {
      case TimerModeModel.focus:
        return TimerMode.focus;
      case TimerModeModel.break_:
        return TimerMode.break_;
    }
  }

  // Map domain status to model
  static TimerStatusModel _mapStatusDomainToModel(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return TimerStatusModel.idle;
      case TimerStatus.running:
        return TimerStatusModel.running;
      case TimerStatus.paused:
        return TimerStatusModel.paused;
      case TimerStatus.break_:
        return TimerStatusModel.break_;
    }
  }

  // Map domain mode to model
  static TimerModeModel _mapModeDomainToModel(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return TimerModeModel.focus;
      case TimerMode.break_:
        return TimerModeModel.break_;
    }
  }

  // Create from domain entity
  factory TimerStateModel.fromEntity(TimerState entity) {
    return TimerStateModel(
      id: entity.id,
      timeRemaining: entity.timeRemaining,
      statusModel: _mapStatusDomainToModel(entity.status),
      pomodorosCompleted: entity.pomodorosCompleted,
      currentTaskId: entity.currentTaskId,
      lastUpdateTime: entity.lastUpdateTime,
      timerModeModel: _mapModeDomainToModel(entity.timerMode),
    );
  }

  // Override copyWith to return TimerStateModel
  @override
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
      statusModel: status != null
          ? _mapStatusDomainToModel(status)
          : statusModel,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      timerModeModel: timerMode != null
          ? _mapModeDomainToModel(timerMode)
          : timerModeModel,
    );
  }
}
