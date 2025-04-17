import 'package:tictask/features/timer/data/datasources/timer_local_datasource.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/data/models/timer_state_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_config.dart';
import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/entities/timer_state.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class TimerRepositoryImpl implements ITimerRepository {
  final TimerLocalDataSource _localDataSource;

  TimerRepositoryImpl(this._localDataSource);

  @override
  Future<void> init() async {
    await _localDataSource.init();
  }

  @override
  Future<TimerConfig> getTimerConfig() async {
    return await _localDataSource.getTimerConfig();
  }

  @override
  Future<void> saveTimerConfig(TimerConfig config) async {
    await _localDataSource.saveTimerConfig(
      config is TimerConfigModel
          ? config
          : TimerConfigModel.fromEntity(config),
    );
  }

  @override
  Future<TimerState> getTimerState() async {
    return await _localDataSource.getTimerState();
  }

  @override
  Future<TimerState> updateTimerState(TimerState state) async {
    return await _localDataSource.updateTimerState(
      state is TimerStateModel
          ? state
          : TimerStateModel.fromEntity(state),
    );
  }

  @override
  Future<void> saveSession(TimerSession session) async {
    await _localDataSource.saveSession(
      session is TimerSessionModel
          ? session
          : TimerSessionModel.fromEntity(session),
    );
  }

  @override
  Future<List<TimerSession>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _localDataSource.getSessionsByDateRange(startDate, endDate);
  }

  @override
  Future<List<TimerSession>> getTodaysSessions() async {
    return await _localDataSource.getTodaysSessions();
  }

  @override
  Future<int> getCompletedPomodoroCountToday() async {
    return await _localDataSource.getCompletedPomodoroCountToday();
  }

  @override
  Future<int> getTotalCompletedPomodoros() async {
    return await _localDataSource.getTotalCompletedPomodoros();
  }

  @override
  Future<void> syncTimerConfig() async {
    // Basic implementation doesn't sync with remote
    return;
  }

  @override
  Future<void> close() async {
    await _localDataSource.close();
  }
}