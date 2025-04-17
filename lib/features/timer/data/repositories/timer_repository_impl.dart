import 'package:tictask/features/timer/data/datasources/timer_local_data_source.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/data/models/timer_state_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

class TimerRepositoryImpl implements ITimerRepository {
  final TimerLocalDataSource _localDataSource;
  
  TimerRepositoryImpl(this._localDataSource);
  
  Future<void> init() async {
    await _localDataSource.init();
  }
  
  @override
  Future<TimerConfigEntity> getTimerConfig() async {
    return await _localDataSource.getTimerConfig();
  }
  
  @override
  Future<void> saveTimerConfig(TimerConfigEntity config) async {
    final configModel = config is TimerConfigModel 
        ? config 
        : TimerConfigModel.fromEntity(config);
    
    await _localDataSource.saveTimerConfig(configModel);
  }
  
  @override
  Future<TimerEntity> getTimerState() async {
    return await _localDataSource.getTimerState();
  }
  
  @override
  Future<TimerEntity> updateTimerState(TimerEntity state) async {
    final stateModel = state is TimerStateModel 
        ? state 
        : TimerStateModel.fromEntity(state);
    
    return await _localDataSource.updateTimerState(stateModel);
  }
  
  @override
  Future<void> saveSession(TimerSessionEntity session) async {
    final sessionModel = session is TimerSessionModel 
        ? session 
        : TimerSessionModel.fromEntity(session);
    
    await _localDataSource.saveSession(sessionModel);
  }
  
  @override
  Future<List<TimerSessionEntity>> getSessionsByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    return await _localDataSource.getSessionsByDateRange(startDate, endDate);
  }
  
  @override
  Future<List<TimerSessionEntity>> getTodaysSessions() async {
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
  
  Future<void> close() async {
    await _localDataSource.close();
  }
}
