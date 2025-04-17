import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/core/utils/logger.dart';
import 'package:tictask/features/timer/data/datasources/timer_local_data_source.dart';
import 'package:tictask/features/timer/data/datasources/timer_remote_data_source.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';
import 'package:tictask/features/timer/data/models/timer_state_model.dart';
import 'package:tictask/features/timer/domain/entities/timer_config_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';

class SyncableTimerRepositoryImpl implements ISyncableTimerRepository {
  final TimerLocalDataSource _localDataSource;
  final TimerRemoteDataSource _remoteDataSource;
  final AuthService _authService;
  
  // Sync state notifiers
  final ValueNotifier<bool> _isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasSyncErrors = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastSyncError = ValueNotifier<String?>(null);
  
  SyncableTimerRepositoryImpl({
    required TimerLocalDataSource localDataSource,
    required TimerRemoteDataSource remoteDataSource,
    required AuthService authService,
  }) : 
    _localDataSource = localDataSource,
    _remoteDataSource = remoteDataSource,
    _authService = authService;
  
  Future<void> init() async {
    await _localDataSource.init();
  }
  
  @override
  ValueNotifier<bool> get isSyncing => _isSyncing;
  
  @override
  ValueNotifier<bool> get hasSyncErrors => _hasSyncErrors;
  
  @override
  ValueNotifier<String?> get lastSyncError => _lastSyncError;
  
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
    
    // Mark for sync
    await _markRecordForSync(session.id);
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
  
  // Sync implementation methods
  
  // Mark a record for sync
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
      
      AppLogger.i('Pushing timer sessions changes: ${pendingSyncIds.length} updates, ${deletedIds.length} deletions');
      
      // Create a map of local sessions for efficient lookup
      final localSessions = <String, TimerSessionModel>{};
      for (final id in pendingSyncIds) {
        final session = await _localDataSource.getSessionById(id);
        if (session != null) {
          localSessions[id] = session;
        }
      }
      
      // Push changes via remote data source
      syncCount = await _remoteDataSource.pushChanges(
        pendingSyncIds,
        deletedIds,
        localSessions,
      );
      
      // Clear sync markers for successfully synced records
      await _clearSyncMarkers(pendingSyncIds);
      
      // Clear deletion markers for successfully deleted records
      await _clearDeletionMarkers(deletedIds);
      
      _isSyncing.value = false;
      return syncCount;
    } catch (e) {
      _isSyncing.value = false;
      _hasSyncErrors.value = true;
      _lastSyncError.value = e.toString();
      AppLogger.e('Push changes error: $e');
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
      
      // Get remote changes from remote data source
      final remoteRecords = await _remoteDataSource.pullChanges(lastSyncTime);
      
      // Get pending sync IDs to avoid overwriting local changes
      final pendingSyncIds = await _getPendingSyncIds();
      
      // Process each remote record
      for (final record in remoteRecords) {
        final id = record.id;
        
        // Skip if this record is pending local sync (would overwrite local changes)
        if (pendingSyncIds.contains(id)) {
          continue;
        }
        
        // Skip if this record is locally deleted
        if (deletedIds.contains(id)) {
          continue;
        }
        
        // Get local record
        final localSession = await _localDataSource.getSessionById(id);
        
        // If local record exists, check which is newer
        if (localSession != null) {
          // Only update if remote is newer
          if (record.endTime >= localSession.endTime) {
            await _localDataSource.saveSession(record);
            syncCount++;
          }
        } else {
          // No local record, just add it
          await _localDataSource.saveSession(record);
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
      AppLogger.e('Pull changes error: $e');
      return 0;
    }
  }
  
  @override
  Future<int> resolveConflicts() async {
    // This is a simplified conflict resolution strategy
    // In a real-world application, you might want to implement a more sophisticated approach
    return 0;
  }
  
  @override
  Future<DateTime?> getLastSyncTime() async {
    return await _remoteDataSource.getLastSyncTime();
  }
  
  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _remoteDataSource.setLastSyncTime(time);
  }
  
  @override
  Future<bool> hasPendingChanges() async {
    final pendingSyncIds = await _getPendingSyncIds();
    final deletedIds = await _getDeletedIds();
    
    return pendingSyncIds.isNotEmpty || deletedIds.isNotEmpty;
  }
  
  @override
  Future<List<TimerSessionEntity>> getLocalModifiedRecords() async {
    final pendingSyncIds = await _getPendingSyncIds();
    
    final sessions = <TimerSessionEntity>[];
    for (final id in pendingSyncIds) {
      final session = await _localDataSource.getSessionById(id);
      if (session != null) {
        sessions.add(session);
      }
    }
    
    return sessions;
  }
  
  @override
  Future<List<TimerSessionEntity>> getRemoteModifiedRecords() async {
    if (!_authService.isAuthenticated) return [];
    
    try {
      final lastSyncTime = await getLastSyncTime();
      return await _remoteDataSource.pullChanges(lastSyncTime);
    } catch (e) {
      AppLogger.e('Error getting remote modified records: $e');
      return [];
    }
  }
  
  @override
  Future<void> syncTimerConfig() async {
    if (!_authService.isAuthenticated) {
      AppLogger.i('Skipping timer config sync: Not authenticated');
      return;
    }
    
    try {
      final config = await getTimerConfig();
      AppLogger.i('Syncing timer config: ${config.id}');
      
      // Save to remote
      await _remoteDataSource.saveTimerConfig(config as TimerConfigModel);
      AppLogger.i('Timer config synced successfully');
    } catch (e) {
      AppLogger.e('Error syncing timer config: $e');
      // Don't rethrow to avoid interrupting the sync process
    }
  }
  
  Future<void> close() async {
    await _localDataSource.close();
  }
}