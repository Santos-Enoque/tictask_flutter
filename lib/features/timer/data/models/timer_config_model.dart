import 'package:hive/hive.dart';
import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';

part 'timer_config_model.g.dart';

@HiveType(typeId: 1)
class TimerConfigModel extends TimerConfigEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final int pomoDuration;

  @HiveField(2)
  @override
  final int shortBreakDuration;

  @HiveField(3)
  @override
  final int longBreakDuration;

  @HiveField(4)
  @override
  final int longBreakInterval;

  const TimerConfigModel({
    this.id = 'default',
    this.pomoDuration = 25 * 60,
    this.shortBreakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
    this.longBreakInterval = 4,
  }) : super(
          id: id,
          pomoDuration: pomoDuration,
          shortBreakDuration: shortBreakDuration,
          longBreakDuration: longBreakDuration,
          longBreakInterval: longBreakInterval,
        );

  // Create a copy with updated fields
  TimerConfigModel copyWith({
    String? id,
    int? pomoDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? longBreakInterval,
  }) {
    return TimerConfigModel(
      id: id ?? this.id,
      pomoDuration: pomoDuration ?? this.pomoDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    );
  }

  // Default config
  static const TimerConfigModel defaultConfig = TimerConfigModel();

  // Factory to create from domain entity
  factory TimerConfigModel.fromEntity(TimerConfigEntity entity) {
    return TimerConfigModel(
      id: entity.id,
      pomoDuration: entity.pomoDuration,
      shortBreakDuration: entity.shortBreakDuration,
      longBreakDuration: entity.longBreakDuration,
      longBreakInterval: entity.longBreakInterval,
    );
  }

  // Convert to map for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pomo_duration': pomoDuration,
      'short_break_duration': shortBreakDuration,
      'long_break_duration': longBreakDuration,
      'long_break_interval': longBreakInterval,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from map from API
  factory TimerConfigModel.fromJson(Map<String, dynamic> json) {
    return TimerConfigModel(
      id: json['id'] as String,
      pomoDuration: json['pomo_duration'] as int,
      shortBreakDuration: json['short_break_duration'] as int,
      longBreakDuration: json['long_break_duration'] as int,
      longBreakInterval: json['long_break_interval'] as int,
    );
  }
}
