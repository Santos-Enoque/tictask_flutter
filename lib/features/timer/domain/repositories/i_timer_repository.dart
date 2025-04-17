import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';

/// Interface for timer repository
abstract class ITimerRepository {
  /// Get the current timer configuration
  Future<TimerConfigEntity> getTimerConfig();
  
  /// Save timer configuration
  Future<void> saveTimerConfig(TimerConfigEntity config);
  
  /// Get the current timer state
  Future<TimerEntity> getTimerState();
  
  /// Update timer state
  Future<TimerEntity> updateTimerState(TimerEntity state);
  
  /// Save completed or interrupted session
  Future<void> saveSession(TimerSessionEntity session);
  
  /// Get sessions for a specific date range
  Future<List<TimerSessionEntity>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get sessions for today
  Future<List<TimerSessionEntity>> getTodaysSessions();
  
  /// Get count of completed pomodoros today
  Future<int> getCompletedPomodoroCountToday();
  
  /// Get total count of completed pomodoros
  Future<int> getTotalCompletedPomodoros();
}
