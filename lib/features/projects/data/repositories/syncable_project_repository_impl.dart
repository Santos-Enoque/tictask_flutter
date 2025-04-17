
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/features/projects/data/datasources/project_local_data_source.dart';
import 'package:tictask/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_syncable_project_repository.dart';

class SyncableProjectRepositoryImpl implements ISyncableProjectRepository {
  final ProjectLocalDataSource _localDataSource;
  final ProjectRemoteDataSource _remoteDataSource;
  final AuthService _authService;
  
  // Sync state notifiers
  final ValueNotifier<bool> _isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasSyncErrors = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastSyncError = ValueNotifier<String?>(null);
  
  SyncableProjectRepositoryImpl({
    required ProjectLocalDataSource localDataSource,
    required ProjectRemoteDataSource remoteDataSource,
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
  Future<List<ProjectEntity>> getAllProjects() async {
    return _localDataSource.getAllProjects();
  }
  
  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    return _localDataSource.getProjectById(id);
  }
  
  @override
  Future<void> saveProject(ProjectEntity project) async {
    final projectModel = project is ProjectModel 
        ? project 
        : ProjectModel.fromEntity(project);
    
    // Save locally
    await _localDataSource.saveProject(projectModel);
    
    // Mark for sync
    await _markRecordForSync(project.id);
  }
  
  @override
  Future<void> deleteProject(String id) async {
    // Don't allow deletion of the default inbox project
    if (id == 'inbox') {
      throw Exception('Cannot delete the default Inbox project');
    }
    
    // Before deleting, mark as deleted in sync table
    await _markRecordAsDeleted(id);

    // Then delete locally
    await _localDataSource.deleteProject(id);
  }
  
  // Mark a record for sync
  Future<void> _markRecordForSync(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_project_sync_ids') ?? [];

    if (!pendingSyncIds.contains(id)) {
      pendingSyncIds.add(id);
      await prefs.setStringList('pending_project_sync_ids', pendingSyncIds);
    }
  }
  
  // Mark a record as deleted for sync
  Future<void> _markRecordAsDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_project_ids') ?? [];

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_project_ids', deletedIds);
    }
  }
  
  // Get pending sync records
  Future<Set<String>> _getPendingSyncIds() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_project_sync_ids') ?? [];
    return pendingSyncIds.toSet();
  }
  
  // Get deleted record IDs
  Future<Set<String>> _getDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_project_ids') ?? [];
    return deletedIds.toSet();
  }
  
  // Clear sync markers for processed records
  Future<void> _clearSyncMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update pending sync IDs
    final pendingSyncIds = prefs.getStringList('pending_project_sync_ids') ?? [];
    pendingSyncIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('pending_project_sync_ids', pendingSyncIds);
  }
  
  // Clear deletion markers for processed records
  Future<void> _clearDeletionMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update deleted IDs
    final deletedIds = prefs.getStringList('deleted_project_ids') ?? [];
    deletedIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('deleted_project_ids', deletedIds);
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

      // Create a map of local projects for efficient lookup
      final localProjects = <String, ProjectModel>{};
      for (final id in pendingSyncIds) {
        final project = await _localDataSource.getProjectById(id);
        if (project != null) {
          localProjects[id] = project;
        }
      }

      // Process updates and deletions via remote data source
      syncCount = await _remoteDataSource.pushChanges(
        pendingSyncIds,
        deletedIds,
        localProjects,
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

        // Skip overwriting the inbox project
        if (id == 'inbox') {
          continue;
        }

        // Get local record
        final localProject = await _localDataSource.getProjectById(id);

        // If local record exists, check which is newer
        if (localProject != null) {
          // Only update if remote is newer
          if (record.updatedAt > localProject.updatedAt) {
            await _localDataSource.saveProject(record);
            syncCount++;
          }
        } else {
          // No local record, just add it
          await _localDataSource.saveProject(record);
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
  Future<List<ProjectEntity>> getLocalModifiedRecords() async {
    final pendingSyncIds = await _getPendingSyncIds();
    
    final projects = <ProjectEntity>[];
    for (final id in pendingSyncIds) {
      final project = await _localDataSource.getProjectById(id);
      if (project != null) {
        projects.add(project);
      }
    }
    
    return projects;
  }
  
  @override
  Future<List<ProjectEntity>> getRemoteModifiedRecords() async {
    if (!_authService.isAuthenticated) return [];
    
    try {
      final lastSyncTime = await getLastSyncTime();
      return await _remoteDataSource.pullChanges(lastSyncTime);
    } catch (e) {
      debugPrint('Error getting remote modified records: $e');
      return [];
    }
  }
  
  @override
  Future<void> syncInboxProject() async {
    try {
      // Get the inbox project
      final inboxProject = await getProjectById('inbox');
      if (inboxProject == null) {
        debugPrint('Inbox project not found, cannot sync');
        return;
      }
      
      // Save to remote
      await _remoteDataSource.saveInboxProject(inboxProject as ProjectModel);
      debugPrint('Inbox project synced successfully');
    } catch (e) {
      debugPrint('Error syncing inbox project: $e');
      throw e;
    }
  }
}