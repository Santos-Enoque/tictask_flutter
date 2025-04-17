import 'package:flutter/foundation.dart';
import 'package:tictask/features/timer/domain/entities/timer_session_entity.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

/// Interface for timer repository with sync capabilities
abstract class ISyncableTimerRepository extends ITimerRepository {
  /// Push local changes to remote
  Future<int> pushChanges();
  
  /// Pull remote changes to local
  Future<int> pullChanges();
  
  /// Resolve conflicts between local and remote data
  Future<int> resolveConflicts();
  
  /// Get last sync time
  Future<DateTime?> getLastSyncTime();
  
  /// Set last sync time
  Future<void> setLastSyncTime(DateTime time);
  
  /// Check if has pending changes
  Future<bool> hasPendingChanges();
  
  /// Get locally modified records
  Future<List<TimerSessionEntity>> getLocalModifiedRecords();
  
  /// Get remotely modified records
  Future<List<TimerSessionEntity>> getRemoteModifiedRecords();
  
  /// Sync timer configuration
  Future<void> syncTimerConfig();
  
  /// Get notifiers for sync state
  ValueNotifier<bool> get isSyncing;
  ValueNotifier<bool> get hasSyncErrors;
  ValueNotifier<String?> get lastSyncError;
}
