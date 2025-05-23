import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/auth/domain/repositories/auth_repository.dart';

class SyncableTaskRepositoryImpl implements ITaskRepository {
  // Local storage
  late Box<TaskModel> _tasksBox;

  // Remote storage client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth repository
  final AuthRepository _authRepository;

  // Sync state notifiers
  final ValueNotifier<bool> _isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasSyncErrors = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastSyncError = ValueNotifier<String?>(null);

  // Table name in Supabase
  static const String _tableName = 'tasks';

  // Sync metadata key prefix
  static const String _lastSyncTimeKey = 'tasks_last_sync_time';

  // Constructor
  SyncableTaskRepositoryImpl(this._authRepository);

  // Initialize repository
  Future<void> init() async {
    try {
      // Open box - adapters should be registered elsewhere
      _tasksBox = await Hive.openBox<TaskModel>(AppConstants.tasksBox);
      debugPrint('SyncableTaskRepositoryImpl initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SyncableTaskRepositoryImpl: $e');
      // Create an empty box as fallback
      _tasksBox = await Hive.openBox<TaskModel>(AppConstants.tasksBox);
    }
  }

  // Sync notifiers (getters)
  ValueNotifier<bool> get isSyncing => _isSyncing;
  ValueNotifier<bool> get hasSyncErrors => _hasSyncErrors;
  ValueNotifier<String?> get lastSyncError => _lastSyncError;

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  @override
  Future<List<TaskEntity>> getIncompleteTasks() async {
    return _tasksBox.values
        .where((task) => task.status != TaskStatus.completed)
        .toList();
  }

  @override
  Future<List<TaskEntity>> getTasksForDate(DateTime date) async {
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    return _tasksBox.values.where((task) {
      // Include ongoing tasks or tasks with date range overlapping this day
      return task.ongoing ||
          (task.startDate <= endOfDay && task.endDate >= startOfDay);
    }).toList();
  }

  @override
  Future<List<TaskEntity>> getTasksInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Convert to start of day for startDate and end of day for endDate
    final rangeStart = DateTime(startDate.year, startDate.month, startDate.day)
        .millisecondsSinceEpoch;
    final rangeEnd =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
            .millisecondsSinceEpoch;

    return _tasksBox.values.where((task) {
      // Include ongoing tasks or tasks with date range overlapping the given range
      return task.ongoing ||
          (task.startDate <= rangeEnd && task.endDate >= rangeStart);
    }).toList();
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    return _tasksBox.get(id);
  }

  // Modified save method with sync metadata
  @override
  Future<void> saveTask(TaskEntity task) async {
    // Create a copy with updated timestamp for syncing
    final now = DateTime.now().millisecondsSinceEpoch;

    // Ensure we have a TaskModel
    final taskModel = task is TaskModel
        ? task.copyWith(updatedAt: now)
        : TaskModel(
            id: task.id,
            title: task.title,
            description: task.description,
            status: task.status,
            createdAt: task.createdAt,
            updatedAt: now,
            completedAt: task.completedAt,
            pomodorosCompleted: task.pomodorosCompleted,
            estimatedPomodoros: task.estimatedPomodoros,
            startDate: task.startDate,
            endDate: task.endDate,
            ongoing: task.ongoing,
            hasReminder: task.hasReminder,
            reminderTime: task.reminderTime,
            projectId: task.projectId,
          );

    // Save locally
    await _tasksBox.put(task.id, taskModel);

    // Mark as needing sync
    await _markRecordForSync(task.id);
  }

  @override
  Future<void> deleteTask(String id) async {
    // Before deleting, mark as deleted in sync table
    await _markRecordAsDeleted(id);

    // Then delete locally
    await _tasksBox.delete(id);
  }

  @override
  Future<void> markTaskAsInProgress(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await saveTask(task.markAsInProgress());
    }
  }

  @override
  Future<void> markTaskAsCompleted(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await saveTask(task.markAsCompleted());
    }
  }

  @override
  Future<void> incrementTaskPomodoro(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await saveTask(task.incrementPomodoro());
    }
  }

  // Add method to get tasks by project
  @override
  Future<List<TaskEntity>> getTasksByProject(String projectId) async {
    return _tasksBox.values
        .where((task) => task.projectId == projectId)
        .toList();
  }

  // Update tasks when a project is deleted (move them to Inbox)
  @override
  Future<void> moveTasksToInbox(String fromProjectId) async {
    final tasks = await getTasksByProject(fromProjectId);
    for (final task in tasks) {
      await saveTask(task.copyWith(projectId: 'inbox'));
    }
  }

  // Sync implementation

  // Mark a record for sync
  Future<void> _markRecordForSync(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? [];

    if (!pendingSyncIds.contains(id)) {
      pendingSyncIds.add(id);
      await prefs.setStringList('pending_task_sync_ids', pendingSyncIds);
    }
  }

  // Mark a record as deleted for sync
  Future<void> _markRecordAsDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? [];

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_task_ids', deletedIds);
    }
  }

  // Get pending sync records
  Future<Set<String>> _getPendingSyncIds() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? [];
    return pendingSyncIds.toSet();
  }

  // Get deleted record IDs
  Future<Set<String>> _getDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? [];
    return deletedIds.toSet();
  }

  // Clear sync markers for processed records
  Future<void> _clearSyncMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Update pending sync IDs
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? [];
    pendingSyncIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('pending_task_sync_ids', pendingSyncIds);
  }

  // Clear deletion markers for processed records
  Future<void> _clearDeletionMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Update deleted IDs
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? [];
    deletedIds.removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('deleted_task_ids', deletedIds);
  }

  // Convert Task to Map for Supabase
  Future<Map<String, dynamic>> _taskToMap(TaskEntity task) async {
    final user = _authRepository.isAuthenticated
        ? await _authRepository.getCurrentUser()
        : null;
    final userId = user?.id;
    debugPrint('Converting task to map: ${task.id}, user_id: $userId');

    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'status': task.status.index,
      'created_at': task.createdAt,
      'updated_at': task.updatedAt,
      'completed_at': task.completedAt,
      'pomodoros_completed': task.pomodorosCompleted,
      'estimated_pomodoros': task.estimatedPomodoros,
      'start_date': task.startDate,
      'end_date': task.endDate,
      'ongoing': task.ongoing,
      'has_reminder': task.hasReminder,
      'reminder_time': task.reminderTime,
      'project_id': task.projectId,
      'user_id': userId,
    };
  }

  // Convert Supabase Map to Task
  TaskModel _mapToTask(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.values[map['status'] as int],
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      completedAt: map['completed_at'] as int?,
      pomodorosCompleted: map['pomodoros_completed'] as int,
      estimatedPomodoros: map['estimated_pomodoros'] as int?,
      startDate: map['start_date'] as int,
      endDate: map['end_date'] as int,
      ongoing: map['ongoing'] as bool,
      hasReminder: map['has_reminder'] as bool,
      reminderTime: map['reminder_time'] as int?,
      projectId: map['project_id'] as String,
    );
  }

  @override
  Future<int> pushChanges() async {
    if (!_authRepository.isAuthenticated) return 0;

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
          final task = _tasksBox.get(id);
          if (task != null) {
            // Check if this task is also marked as deleted
            if (deletedIds.contains(id)) {
              // Skip updating it since it will be deleted
              continue;
            }

            // Push to Supabase
            final taskMap = await _taskToMap(task);
            await _supabase.from(_tableName).upsert(taskMap).eq('id', id);

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
    if (!_authRepository.isAuthenticated) return 0;

    _isSyncing.value = true;

    try {
      int syncCount = 0;

      // Get last sync time
      final lastSyncTime = await getLastSyncTime();

      // Get deleted IDs to not re-add deleted items
      final deletedIds = await _getDeletedIds();

      // Query for changes since last sync
      final currentUser = await _authRepository.getCurrentUser();
      final userId = currentUser?.id ?? '';

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
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

        // Get local record
        final localTask = _tasksBox.get(id);

        // If local record exists, check which is newer
        if (localTask != null) {
          final remoteUpdatedAt = recordMap['updated_at'] as int;

          // Only update if remote is newer
          if (remoteUpdatedAt > localTask.updatedAt) {
            final task = _mapToTask(recordMap);
            await _tasksBox.put(id, task);
            syncCount++;
          }
        } else {
          // No local record, just add it
          final task = _mapToTask(recordMap);
          await _tasksBox.put(id, task);
          syncCount++;
        }
      }

      // Query for deleted records
      final deletedResponse = await _supabase
          .from('deleted_records')
          .select()
          .eq('user_id', userId)
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

        // Delete locally if it exists
        if (_tasksBox.containsKey(id)) {
          await _tasksBox.delete(id);
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
  Future<bool> hasPendingChanges() async {
    final pendingSyncIds = await _getPendingSyncIds();
    final deletedIds = await _getDeletedIds();

    return pendingSyncIds.isNotEmpty || deletedIds.isNotEmpty;
  }

  // Last sync time methods
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await _authRepository.getCurrentUser();
    final userId = currentUser?.id;

    if (userId == null) return null;

    final key = '${_lastSyncTimeKey}_$userId';
    final timestamp = prefs.getInt(key);

    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = await _authRepository.getCurrentUser();
    final userId = currentUser?.id;

    if (userId == null) return;

    final key = '${_lastSyncTimeKey}_$userId';
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }

  // Clean up resources
  Future<void> close() async {
    await _tasksBox.close();
  }
}
