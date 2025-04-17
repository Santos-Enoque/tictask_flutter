import 'package:tictask/features/timer/domain/entities/timer_config.dart';
import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/entities/timer_state.dart';

/// Interface defining timer repository operations
abstract class ITimerRepository {
  /// Initialize the repository
  Future<void> init();
  
  /// Get timer configuration
  Future<TimerConfig> getTimerConfig();
  
  /// Save timer configuration
  Future<void> saveTimerConfig(TimerConfig config);
  
  /// Get current timer state
  Future<TimerState> getTimerState();
  
  /// Update timer state
  Future<TimerState> updateTimerState(TimerState state);
  
  /// Save a timer session
  Future<void> saveSession(TimerSession session);
  
  /// Get sessions within a date range
  Future<List<TimerSession>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get today's sessions
  Future<List<TimerSession>> getTodaysSessions();
  
  /// Get count of completed pomodoros today
  Future<int> getCompletedPomodoroCountToday();
  
  /// Get total completed pomodoros
  Future<int> getTotalCompletedPomodoros();
  
  /// Sync timer configuration with remote
  Future<void> syncTimerConfig();
  
  /// Close the repository and clean up resources
  Future<void> close();
}
