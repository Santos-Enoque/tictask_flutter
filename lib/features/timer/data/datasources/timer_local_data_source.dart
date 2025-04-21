import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/data/models/timer_state_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';

abstract class TimerLocalDataSource {
  /// Initialize data source
  Future<void> init();

  /// Get timer configuration
  Future<TimerConfigModel> getTimerConfig();

  /// Save timer configuration
  Future<void> saveTimerConfig(TimerConfigModel config);

  /// Get timer state
  Future<TimerStateModel> getTimerState();

  /// Update timer state
  Future<TimerStateModel> updateTimerState(TimerStateModel state);

  /// Save a timer session
  Future<void> saveSession(TimerSessionModel session);

  /// Get a specific timer session by ID
  Future<TimerSessionModel?> getSessionById(String id);

  /// Get sessions by date range
  Future<List<TimerSessionModel>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get sessions for today
  Future<List<TimerSessionModel>> getTodaysSessions();

  /// Get count of completed pomodoros today
  Future<int> getCompletedPomodoroCountToday();

  /// Get total count of completed pomodoros
  Future<int> getTotalCompletedPomodoros();

  /// Close data source
  Future<void> close();
}

class TimerLocalDataSourceImpl implements TimerLocalDataSource {
  late Box<TimerConfigModel> _configBox;
  late Box<TimerStateModel> _stateBox;
  late Box<TimerSessionModel> _sessionsBox;

  static const String _configBoxName = AppConstants.timerConfigBox;
  static const String _stateBoxName = AppConstants.timerStateBox;
  static const String _sessionsBoxName = AppConstants.timerSessionBox;

  @override
  Future<void> init() async {
    try {
      // Register adapters if not already registered
      _registerAdapters();

      // Open boxes
      _configBox = await Hive.openBox<TimerConfigModel>(_configBoxName);
      _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
      _sessionsBox = await Hive.openBox<TimerSessionModel>(_sessionsBoxName);

      // Initialize with default values if empty
      if (_configBox.isEmpty) {
        await _configBox.put('default', TimerConfigModel.defaultConfig);
      }

      if (_stateBox.isEmpty) {
        await _stateBox.put('default', TimerStateModel.defaultState);
      }

      print('TimerLocalDataSource initialized successfully');
    } catch (e) {
      print('Error initializing TimerLocalDataSource: $e');

      // Try to recover by creating default instances
      try {
        // If boxes weren't opened, try to open them
        if (!Hive.isBoxOpen(_configBoxName)) {
          _configBox = await Hive.openBox<TimerConfigModel>(_configBoxName);
        }
        if (!Hive.isBoxOpen(_stateBoxName)) {
          _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
        }
        if (!Hive.isBoxOpen(_sessionsBoxName)) {
          _sessionsBox =
              await Hive.openBox<TimerSessionModel>(_sessionsBoxName);
        }

        // Initialize with default values
        if (_configBox.isEmpty) {
          await _configBox.put('default', TimerConfigModel.defaultConfig);
        }
        if (_stateBox.isEmpty) {
          await _stateBox.put('default', TimerStateModel.defaultState);
        }

        print('TimerLocalDataSource recovered from error');
      } catch (recoveryError) {
        print('Failed to recover TimerLocalDataSource: $recoveryError');
        // Create empty boxes as a last resort
        _configBox = await Hive.openBox<TimerConfigModel>(_configBoxName);
        _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
        _sessionsBox = await Hive.openBox<TimerSessionModel>(_sessionsBoxName);
      }
    }
  }

  void _registerAdapters() {
    // Register adapters for TimerStatus and TimerMode if not already registered
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TimerStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TimerModeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    // Register adapters for models
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimerConfigModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimerSessionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimerStateModelAdapter());
    }
  }

  @override
  Future<TimerConfigModel> getTimerConfig() async {
    return _configBox.get('default') ?? TimerConfigModel.defaultConfig;
  }

  @override
  Future<void> saveTimerConfig(TimerConfigModel config) async {
    await _configBox.put('default', config);
  }

  @override
  Future<TimerStateModel> getTimerState() async {
    return _stateBox.get('default') ?? TimerStateModel.defaultState;
  }

  @override
  Future<TimerStateModel> updateTimerState(TimerStateModel state) async {
    await _stateBox.put('default', state);
    return state;
  }

  @override
  Future<void> saveSession(TimerSessionModel session) async {
    await _sessionsBox.put(session.id, session);
  }

  @override
  Future<TimerSessionModel?> getSessionById(String id) async {
    return _sessionsBox.get(id);
  }

  @override
  Future<List<TimerSessionModel>> getSessionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    return _sessionsBox.values
        .where(
          (session) =>
              session.date.isAfter(startDate) &&
              session.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  @override
  Future<List<TimerSessionModel>> getTodaysSessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getSessionsByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<int> getCompletedPomodoroCountToday() async {
    final sessions = await getTodaysSessions();
    return sessions
        .where((s) => s.type == SessionType.pomodoro && s.completed)
        .length;
  }

  @override
  Future<int> getTotalCompletedPomodoros() async {
    return _sessionsBox.values
        .where((s) => s.type == SessionType.pomodoro && s.completed)
        .length;
  }

  @override
  Future<void> close() async {
    await _configBox.close();
    await _stateBox.close();
    await _sessionsBox.close();
  }
}
