import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/app/repositories/syncable_repository.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';

class SyncableProjectRepository extends ProjectRepository
    implements SyncableRepository<Project> {
  // Local storage
  late Box<Project> _projectsBox;

  // Remote storage client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth service for user information
  final AuthService _authService;

  // Sync state notifiers
  final ValueNotifier<bool> _isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasSyncErrors = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastSyncError = ValueNotifier<String?>(null);

  // Table name in Supabase
  static const String _tableName = 'projects';

  // Sync metadata key prefix
  static const String _lastSyncTimeKey = 'projects_last_sync_time';

  // Constructor
  SyncableProjectRepository(this._authService);

  // Initialize repository
  @override
  Future<void> init() async {
    try {
      // Register class adapters
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(ProjectAdapter());
      }

      // Open box
      _projectsBox = await Hive.openBox<Project>('projects_box');

      // Create default Inbox project if it doesn't exist
      if (_projectsBox.isEmpty) {
        await _projectsBox.put('inbox', Project.inbox());
        print('Default Inbox project created');
      }

      print('SyncableProjectRepository initialized successfully');
    } catch (e) {
      print('Error initializing SyncableProjectRepository: $e');
      // Create an empty box as fallback
      _projectsBox = await Hive.openBox<Project>('projects_box');

      // Ensure default project exists
      if (_projectsBox.get('inbox') == null) {
        await _projectsBox.put('inbox', Project.inbox());
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

  // Override base methods to include sync tracking
  @override
  Future<List<Project>> getAllProjects() async {
    return _projectsBox.values.toList();
  }

  @override
  Future<Project?> getProjectById(String id) async {
    return _projectsBox.get(id);
  }

  @override
  Future<void> saveProject(Project project) async {
    // Save locally
    await _projectsBox.put(project.id, project);

    // Mark as needing sync
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
    await _projectsBox.delete(id);
  }

  // Sync implementation
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

  // Convert Project to Map for Supabase
  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'color': project.color,
      'emoji': project.emoji,
      'created_at': project.createdAt,
      'updated_at': project.updatedAt,
      'is_default': project.isDefault,
      'user_id': _authService.userId,
    };
  }

  // Convert Supabase Map to Project
  Project _mapToProject(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      emoji: map['emoji'] as String?,
      color: map['color'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      isDefault: map['is_default'] as bool,
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
          final project = _projectsBox.get(id);
          if (project != null) {
            // Check if this project is also marked as deleted
            if (deletedIds.contains(id)) {
              // Skip updating it since it will be deleted
              continue;
            }

            // Push to Supabase
            final projectMap = _projectToMap(project);
            await _supabase.from(_tableName).upsert(projectMap).eq('id', id);

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
          .gte('updated_at', lastSyncTime?.millisecondsSinceEpoch ?? 0);

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

        // Skip overwriting the inbox project
        if (id == 'inbox') {
          continue;
        }

        // Get local record
        final localProject = _projectsBox.get(id);

        // If local record exists, check which is newer
        if (localProject != null) {
          final remoteUpdatedAt = recordMap['updated_at'] as int;

          // Only update if remote is newer
          if (remoteUpdatedAt > localProject.updatedAt) {
            final project = _mapToProject(recordMap);
            await _projectsBox.put(id, project);
            syncCount++;
          }
        } else {
          // No local record, just add it
          final project = _mapToProject(recordMap);
          await _projectsBox.put(id, project);
          syncCount++;
        }
      }

      // Query for deleted records
      final deletedResponse = await _supabase
          .from('deleted_records')
          .select()
          .eq('user_id', _authService.userId ?? '')
          .eq('table_name', _tableName)
          .gte('deleted_at', lastSyncTime?.millisecondsSinceEpoch ?? 0);

      final deletedRecords = deletedResponse as List<dynamic>;

      // Process deletes
      for (final record in deletedRecords) {
        final recordMap = record as Map<String, dynamic>;
        final id = recordMap['record_id'] as String;

        // Skip if this record is pending local sync
        if (pendingSyncIds.contains(id)) {
          continue;
        }

        // Skip deleting the inbox project
        if (id == 'inbox') {
          continue;
        }

        // Delete locally if it exists
        if (_projectsBox.containsKey(id)) {
          await _projectsBox.delete(id);
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
    // For now we're using a simple "last write wins" strategy in our push/pull methods
    // A more sophisticated conflict resolution would be implemented here
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

  @override
  Future<List<Project>> getLocalModifiedRecords() async {
    final pendingSyncIds = await _getPendingSyncIds();

    final projects = <Project>[];
    for (final id in pendingSyncIds) {
      final project = _projectsBox.get(id);
      if (project != null) {
        projects.add(project);
      }
    }

    return projects;
  }

  @override
  Future<List<Project>> getRemoteModifiedRecords() async {
    if (!_authService.isAuthenticated) return [];

    try {
      final lastSyncTime = await getLastSyncTime();

      // Query for changes since last sync
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', _authService.userId ?? '')
          .gte('updated_at', lastSyncTime?.millisecondsSinceEpoch ?? 0);

      final remoteRecords = response as List<dynamic>;

      return remoteRecords
          .map((record) => _mapToProject(record as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting remote modified records: $e');
      return [];
    }
  }

  Future<void> syncInboxProject() async {
  try {
    // Get the inbox project
    final inboxProject = await getProjectById('inbox');
    if (inboxProject == null) {
      debugPrint('Inbox project not found, cannot sync');
      return;
    }
    
    // Convert to map
    final projectMap = _projectToMap(inboxProject);
    
    // Upsert to Supabase
    await _supabase.from(_tableName).upsert(projectMap).eq('id', 'inbox');
    debugPrint('Inbox project synced successfully');
  } catch (e) {
      debugPrint('Error syncing inbox project: $e');
      throw e;
    }
  }
}