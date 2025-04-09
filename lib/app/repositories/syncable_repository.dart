import 'package:flutter/foundation.dart';

/// Base interface for repositories that support synchronization
abstract class SyncableRepository<T> {
  /// Push local changes to remote database
  /// Returns number of records synced
  Future<int> pushChanges();
  
  /// Pull remote changes from server
  /// Returns number of records synced
  Future<int> pullChanges();
  
  /// Handle conflicts between local and remote data
  /// Returns number of conflicts resolved
  Future<int> resolveConflicts();
  
  /// Get last sync time for this repository
  Future<DateTime?> getLastSyncTime();
  
  /// Set last sync time for this repository
  Future<void> setLastSyncTime(DateTime time);
  
  /// Check if repository has pending local changes
  Future<bool> hasPendingChanges();
  
  /// Get local modified records since last sync
  Future<List<T>> getLocalModifiedRecords();
  
  /// Get remote modified records since last sync
  Future<List<T>> getRemoteModifiedRecords();
  
  /// Flag to indicate if repository is currently syncing
  ValueNotifier<bool> get isSyncing;
  
  /// Flag to indicate if repository has sync errors
  ValueNotifier<bool> get hasSyncErrors;
  
  /// Error message from last sync attempt
  ValueNotifier<String?> get lastSyncError;
}