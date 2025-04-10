import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/core/utils/logger.dart';
import 'package:tictask/features/timer/models/models.dart';

class TimerRepository {
  static const String _configBoxName = AppConstants.timerConfigBox;
  static const String _stateBoxName = AppConstants.timerStateBox;
  static const String _sessionsBoxName = AppConstants.timerSessionBox;

  late Box<TimerConfig> _configBox;
  late Box<TimerStateModel> _stateBox;
  late Box<TimerSession> _sessionsBox;

  // Initialize repository
  Future<void> init() async {
    try {
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

      print('TimerRepository initialized successfully');
    } catch (e) {
      print('Error initializing TimerRepository: $e');

      // Try to recover by creating default instances
      try {
        // If boxes weren't opened, try to open them
        if (!Hive.isBoxOpen(_configBoxName)) {
          _configBox = await Hive.openBox<TimerConfig>(_configBoxName);
        }
        if (!Hive.isBoxOpen(_stateBoxName)) {
          _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
        }
        if (!Hive.isBoxOpen(_sessionsBoxName)) {
          _sessionsBox = await Hive.openBox<TimerSession>(_sessionsBoxName);
        }

        // Initialize with default values
        if (_configBox.isEmpty) {
          await _configBox.put('default', TimerConfig.defaultConfig);
        }
        if (_stateBox.isEmpty) {
          await _stateBox.put('default', TimerStateModel.defaultState);
        }

        print('TimerRepository recovered from error');
      } catch (recoveryError) {
        print('Failed to recover TimerRepository: $recoveryError');
        // Create empty boxes as a last resort
        _configBox = await Hive.openBox<TimerConfig>(_configBoxName);
        _stateBox = await Hive.openBox<TimerStateModel>(_stateBoxName);
        _sessionsBox = await Hive.openBox<TimerSession>(_sessionsBoxName);
      }
    }
  }

  // Timer config methods
Future<TimerConfig> getTimerConfig() async {
  try {
    // Try to get from Hive box, handle any potential errors
    final config = _configBox.get('default');
    if (config != null) {
      AppLogger.i('Retrieved timer config from Hive');
      return config;
    } else {
      AppLogger.w('No timer config found in Hive, using default');
      return TimerConfig.defaultConfig;
    }
  } catch (e) {
    AppLogger.e('Error getting timer config from Hive: $e');
    return TimerConfig.defaultConfig;
  }
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
     AppLogger.i('Saving timer session: ${session.id}');
  
  // Save locally
  await _sessionsBox.put(session.id, session);

  // Mark for sync - add debug logging
  await _markRecordForSync(session.id);
  }

  // Update the _markRecordForSync method to add logging
Future<void> _markRecordForSync(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final pendingSyncIds = prefs.getStringList('pending_timer_session_sync_ids') ?? [];

  AppLogger.i('Marking session for sync: $id (current pending count: ${pendingSyncIds.length})');

  if (!pendingSyncIds.contains(id)) {
    pendingSyncIds.add(id);
    await prefs.setStringList('pending_timer_session_sync_ids', pendingSyncIds);
    AppLogger.i('Session marked for sync successfully, new pending count: ${pendingSyncIds.length}');
  } else {
    AppLogger.i('Session already marked for sync, skipping');
  }
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
