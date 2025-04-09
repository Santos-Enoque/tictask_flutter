import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/app/repositories/syncable_repository.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';

class SyncableTimerRepository extends TimerRepository
    implements SyncableRepository<TimerSession> {
  // Local storage
  late Box<TimerConfig> _configBox;
  late Box<TimerStateModel> _stateBox;
  late Box<TimerSession> _sessionsBox;

  // Remote storage client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth service for user information
  final AuthService _authService;

  // Sync state notifiers
  final ValueNotifier<bool> _isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasSyncErrors = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastSyncError = ValueNotifier<String?>(null);

  // Table name in Supabase
  static const String _tableName = 'timer_sessions';

  // Sync metadata key prefix
  static const String _lastSyncTimeKey = 'timer_sessions_last_sync_time';

  // Constructor
  SyncableTimerRepository(this._authService);

  // Initialize repository
  @override
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
      _configBox = await Hive.openBox<TimerConfig>(AppConstants.timerConfigBox);
      _stateBox = await Hive.openBox<TimerStateModel>(AppConstants.timerStateBox);
      _sessionsBox = await Hive.openBox<TimerSession>(AppConstants.timerSessionBox);

      // Initialize with default values if empty
      if (_configBox.isEmpty) {
        await _configBox.put('default', TimerConfig.defaultConfig);
      }

      if (_stateBox.isEmpty) {
        await _stateBox.put('default', TimerStateModel.defaultState);
      }

      print('SyncableTimerRepository initialized successfully');
    } catch (e) {
      print('Error initializing SyncableTimerRepository: $e');

      // Try to recover by creating default instances
      try {
        // If boxes weren't opened, try to open them
        if (!Hive.isBoxOpen(AppConstants.timerConfigBox)) {
          _configBox = await Hive.openBox<TimerConfig>(AppConstants.timerConfigBox);
        }
        if (!Hive.isBoxOpen(AppConstants.timerStateBox)) {
          _stateBox = await Hive.openBox<TimerStateModel>(AppConstants.timerStateBox);
        }
        if (!Hive.isBoxOpen(AppConstants.timerSessionBox)) {
          _sessionsBox = await Hive.openBox<TimerSession>(AppConstants.timerSessionBox);
        }

        // Initialize with default values
        if (_configBox.isEmpty) {
          await _configBox.put('default', TimerConfig.defaultConfig);
        }
        if (_stateBox.isEmpty) {
          await _stateBox.put('default', TimerStateModel.defaultState);
        }

        print('SyncableTimerRepository recovered from error');
      } catch (recoveryError) {
        print('Failed to recover SyncableTimerRepository: $recoveryError');
        // Create empty boxes as a last resort
        _configBox = await Hive.openBox<TimerConfig>(AppConstants.timerConfigBox);
        _stateBox = await Hive.openBox<TimerStateModel>(AppConstants.timerStateBox);
        _sessionsBox = await Hive.openBox<TimerSession>(AppConstants.timerSessionBox);
      }
    }
  }

  // Sync notifiers
  @override
  ValueNotifier<bool> get isSyncing => _isSyncing;

  @override
  ValueNotifier<bool> get hasSyncErrors => _hasSyncErrors;

  @override
  ValueNotifier<String?> get lastSyncError => _lastSyncError;
  
  // Override session saving to include sync tracking
  @override
  Future<void> saveSession(TimerSession session) async {
    // Save locally
    await _sessionsBox.put(session.id, session);
    
    // Mark for sync
    await _markRecordForSync(session.id);
  }

  // Sync implementation methods
  // Mark a record for sync
  Future<void> _markRecordForSync(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_timer_session_sync_ids') ?? [];

    if (!pendingSyncIds.contains(id)) {
      pendingSyncIds.add(id);
      await prefs.setStringList('pending_timer_session_sync_ids', pendingSyncIds);
    }
  }

  // Mark a record as deleted for sync
  Future<void> _markRecordAsDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_timer_session_ids') ?? [];

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_timer_session_ids', deletedIds);
    }
  }

  // Get pending sync records
  Future<Set<String>> _getPendingSyncIds() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_timer_session_sync_ids') ?? [];
    return pendingSyncIds.toSet();
  }

  // Get deleted record IDs
  Future<Set<String>> _getDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_timer_session_ids') ?? [];
    return deletedIds.toSet();
  }

  // Clear sync markers for processed records
  Future<void> _clearSyncMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Update pending sync IDs
    final pendingSyncIds = prefs.getStringList('pending_timer_session_sync_ids') ?? [];
    pendingSyncIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('pending_timer_session_sync_ids', pendingSyncIds);
  }

  // Clear deletion markers for processed records
  Future<void> _clearDeletionMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Update deleted IDs
    final deletedIds = prefs.getStringList('deleted_timer_session_ids') ?? [];
    deletedIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('deleted_timer_session_ids', deletedIds);
  }

  // Convert TimerSession to Map for Supabase
  Map<String, dynamic> _sessionToMap(TimerSession session) {
    return {
      'id': session.id,
      'date': session.date.toIso8601String(),
      'start_time': session.startTime,
      'end_time': session.endTime,
      'duration': session.duration,
      'type': session.type.index,
      'completed': session.completed,
      'task_id': session.taskId,
      'user_id': _authService.userId,
    };
  }
  
  // Convert Supabase Map to TimerSession
  TimerSession _mapToSession(Map<String, dynamic> map) {
    return TimerSession(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int,
      duration: map['duration'] as int,
      type: SessionType.values[map['type'] as int],
      completed: map['completed'] as bool,
      taskId: map['task_id'] as String?,
    );
  }

  @override
  Future<int> pushChanges() async {
    if (!_authService.isAuthenticated) return 0;

    _isSyncing.value = true;
    _hasSyncErrors.value = false;
    _lastSyncError.value = null;

    try {
      int syncCount = 0;

      // Get pending changes
      final pendingSyncIds = await _getPendingSyncIds();
      final deletedIds = await _getDeletedIds();

      // Process updates
      if (pendingSyncIds.isNotEmpty) {
        final syncedIds = <String>{};

        for (final id in pendingSyncIds) {
          final session = _sessionsBox.get(id);
          if (session != null) {
            // Check if this session is also marked as deleted
            if (deletedIds.contains(id)) {
              // Skip updating it since it will be deleted
              continue;
            }

            // Push to Supabase
            final sessionMap = _sessionToMap(session);
            await _supabase.from(_tableName).upsert(sessionMap).eq('id', id);

            syncedIds.add(id);
            syncCount++;
          }
        }

        // Clear sync markers for successfully synced records
        await _clearSyncMarkers(syncedIds);
      }

      // Process deletions
      if (deletedIds.isNotEmpty) {
        final deletedSyncedIds = <String>{};

        for (final id in deletedIds) {
          // Delete from Supabase
          await _supabase.from(_tableName).delete().eq('id', id);

          deletedSyncedIds.add(id);
          syncCount++;
        }

        // Clear deletion markers for successfully deleted records
        await _clearDeletionMarkers(deletedSyncedIds);
      }

      _isSyncing.value = false;
      return syncCount;
    } catch (e) {
      _isSyncing.value = false;
      _hasSyncErrors.value = true;
      _lastSyncError.value = e.toString();
      debugPrint('Push changes error: $e');
      return 0;
    }
  }

  @override
  Future<int> pullChanges() async {
    if (!_authService.isAuthenticated) return 0;

    _isSyncing.value = true;

    try {
      int syncCount = 0;

      // Get last sync time
      final lastSyncTime = await getLastSyncTime();

      // Get deleted IDs to not re-add deleted items
      final deletedIds = await _getDeletedIds();

      // Query for changes since last sync
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _authService.userId ?? '')
          .gte('end_time', lastSyncTime?.millisecondsSinceEpoch ?? 0);

      final remoteRecords = response as List<dynamic>;

      // Get pending sync IDs to avoid overwriting local changes
      final pendingSyncIds = await _getPendingSyncIds();

      // Process each remote record
      for (final record in remoteRecords) {
        final recordMap = record as Map<String, dynamic>;
        final id = recordMap['id'] as String;

        // Skip if this record is pending local sync (would overwrite local changes)
        if (pendingSyncIds.contains(id)) {
          continue;
        }

        // Skip if this record is locally deleted
        if (deletedIds.contains(id)) {
          continue;
        }

        // Get local record
        final localSession = _sessionsBox.get(id);

        // If local record exists, check which is newer
        if (localSession != null) {
          final remoteEndTime = recordMap['end_time'] as int;

          // Only update if remote is newer or same (assuming it has more data)
          if (remoteEndTime >= localSession.endTime) {
            final session = _mapToSession(recordMap);
            await _sessionsBox.put(id, session);
            syncCount++;
          }
        } else {
          // No local record, just add it
          final session = _mapToSession(recordMap);
          await _sessionsBox.put(id, session);
          syncCount++;
        }
      }

      // Update last sync time
      await setLastSyncTime(DateTime.now());

      _isSyncing.value = false;
      return syncCount;
    } catch (e) {
      _isSyncing.value = false;
      _hasSyncErrors.value = true;
      _lastSyncError.value = e.toString();
      debugPrint('Pull changes error: $e');
      return 0;
    }
  }

  @override
  Future<int> resolveConflicts() async {
    // This method would handle conflict resolution between local and remote data
    // For timer sessions, the strategy is simpler - we generally don't edit sessions after creation
    return 0;
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.userId;

    if (userId == null) return null;

    final key = '${_lastSyncTimeKey}_$userId';
    final timestamp = prefs.getInt(key);

    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.userId;

    if (userId == null) return;

    final key = '${_lastSyncTimeKey}_$userId';
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }

  @override
  Future<bool> hasPendingChanges() async {
    final pendingSyncIds = await _getPendingSyncIds();
    final deletedIds = await _getDeletedIds();

    return pendingSyncIds.isNotEmpty || deletedIds.isNotEmpty;
  }
// Add method to sync timer configuration
Future<void> syncTimerConfig() async {
  try {
    final config = await getTimerConfig();
    debugPrint('Syncing timer config: ${config.id}');
    
    // Convert to map
    final configMap = {
      'id': config.id,
      'pomo_duration': config.pomoDuration,
      'short_break_duration': config.shortBreakDuration,
      'long_break_duration': config.longBreakDuration,
      'long_break_interval': config.longBreakInterval,
      'user_id': _authService.userId,
    };
    
    // Upsert to Supabase
    await _supabase.from('timer_config').upsert(configMap).eq('id', config.id);
    debugPrint('Timer config synced successfully');
  } catch (e) {
    debugPrint('Error syncing timer config: $e');
    throw e;
  }
}
  @override
  Future<List<TimerSession>> getLocalModifiedRecords() async {
    final pendingSyncIds = await _getPendingSyncIds();

    final sessions = <TimerSession>[];
    for (final id in pendingSyncIds) {
      final session = _sessionsBox.get(id);
      if (session != null) {
        sessions.add(session);
      }
    }

    return sessions;
  }

  @override
  Future<List<TimerSession>> getRemoteModifiedRecords() async {
    if (!_authService.isAuthenticated) return [];

    try {
      final lastSyncTime = await getLastSyncTime();

      // Query for changes since last sync
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _authService.userId ?? '')
          .gte('end_time', lastSyncTime?.millisecondsSinceEpoch ?? 0);

      final remoteRecords = response as List<dynamic>;

      return remoteRecords
          .map((record) => _mapToSession(record as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting remote modified records: $e');
      return [];
    }
  }
}