
import 'package:flutter/foundation.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';

/// Interface for project repository with sync capabilities
abstract class ISyncableProjectRepository extends IProjectRepository {
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
  Future<List<ProjectEntity>> getLocalModifiedRecords();
  
  /// Get remotely modified records
  Future<List<ProjectEntity>> getRemoteModifiedRecords();
  
  /// Sync inbox project specifically
  Future<void> syncInboxProject();
  
  /// Get notifiers for sync state
  ValueNotifier<bool> get isSyncing;
  ValueNotifier<bool> get hasSyncErrors;
  ValueNotifier<String?> get lastSyncError;
}
