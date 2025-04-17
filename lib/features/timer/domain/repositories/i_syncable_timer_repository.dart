import 'package:flutter/foundation.dart';
import 'package:tictask/app/repositories/syncable_repository.dart';
import 'package:tictask/features/timer/domain/entities/timer_session.dart';
import 'package:tictask/features/timer/domain/repositories/i_timer_repository.dart';

/// Interface extending ITimerRepository with sync capabilities
abstract class ISyncableTimerRepository extends ITimerRepository implements SyncableRepository<TimerSession> {
  /// ValueNotifier for syncing state
  ValueNotifier<bool> get isSyncing;
  
  /// ValueNotifier for sync errors
  ValueNotifier<bool> get hasSyncErrors;
  
  /// ValueNotifier for last sync error message
  ValueNotifier<String?> get lastSyncError;
  
  /// Push local changes to remote
  @override
  Future<int> pushChanges();
  
  /// Pull remote changes
  @override
  Future<int> pullChanges();
  
  /// Resolve conflicts between local and remote data
  @override
  Future<int> resolveConflicts();
  
  /// Get the timestamp of the last sync
  @override
  Future<DateTime?> getLastSyncTime();
  
  /// Set the timestamp of the last sync
  @override
  Future<void> setLastSyncTime(DateTime time);
  
  /// Check if there are pending changes to sync
  @override
  Future<bool> hasPendingChanges();
  
  /// Get locally modified records since last sync
  @override
  Future<List<TimerSession>> getLocalModifiedRecords();
  
  /// Get remotely modified records since last sync
  @override
  Future<List<TimerSession>> getRemoteModifiedRecords();
}
