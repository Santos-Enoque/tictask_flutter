import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/features/timer/models/models.dart';

class TimerRepository {
  static const String _configBoxName = 'timer_config';
  static const String _stateBoxName = 'timer_state';
  static const String _sessionsBoxName = 'timer_sessions';

  late Box<TimerConfig> _configBox;
  late Box<TimerStateModel> _stateBox;
  late Box<TimerSession> _sessionsBox;

  // Initialize repository
  Future<void> init() async {
    // Register enum adapters
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TimerStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TimerModeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    // Register class adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimerConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimerSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimerStateModelAdapter());
    }

    // Open boxes
    _configBox = await Hive.openBox<TimerConfig>(_configBoxName);
    _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
    _sessionsBox = await Hive.openBox<TimerSession>(_sessionsBoxName);

    // Initialize with default values if empty
    if (_configBox.isEmpty) {
      await _configBox.put('default', TimerConfig.defaultConfig);
    }

    if (_stateBox.isEmpty) {
      await _stateBox.put('default', TimerStateModel.defaultState);
    }
  }

  // Timer config methods
  Future<TimerConfig> getTimerConfig() async {
    return _configBox.get('default') ?? TimerConfig.defaultConfig;
  }

  Future<void> saveTimerConfig(TimerConfig config) async {
    await _configBox.put('default', config);
  }

  // Timer state methods
  Future<TimerStateModel> getTimerState() async {
    return _stateBox.get('default') ?? TimerStateModel.defaultState;
  }

  Future<TimerStateModel> updateTimerState(TimerStateModel state) async {
    await _stateBox.put('default', state);
    return state;
  }

  // Timer session methods
  Future<void> saveSession(TimerSession session) async {
    await _sessionsBox.put(session.id, session);
  }

  Future<List<TimerSession>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _sessionsBox.values
        .where(
          (session) =>
              session.date.isAfter(startDate) &&
              session.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  Future<List<TimerSession>> getTodaysSessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getSessionsByDateRange(startOfDay, endOfDay);
  }

  Future<int> getCompletedPomodoroCountToday() async {
    final sessions = await getTodaysSessions();
    return sessions
        .where((s) => s.type == SessionType.pomodoro && s.completed)
        .length;
  }

  Future<int> getTotalCompletedPomodoros() async {
    return _sessionsBox.values
        .where((s) => s.type == SessionType.pomodoro && s.completed)
        .length;
  }

  // Clean up resources
  Future<void> close() async {
    await _configBox.close();
    await _stateBox.close();
    await _sessionsBox.close();
  }
}
