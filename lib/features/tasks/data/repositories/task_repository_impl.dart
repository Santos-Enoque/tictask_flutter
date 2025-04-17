import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:tictask/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';
import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.uuid,
  });
  final TaskLocalDataSource localDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final Uuid uuid;

  @override
  Future<List<Task>> getAllTasks() async {
    return localDataSource.getAllTasks();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    return localDataSource.getTaskById(id);
  }

  @override
  Future<void> saveTask(Task task) async {
    // Convert to model if not already
    final taskModel = task is TaskModel
        ? task
        : TaskModel(
            id: task.id,
            title: task.title,
            description: task.description,
            status: task.status,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
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
    await localDataSource.saveTask(taskModel);

    // Mark for sync
    await _markForSync(taskModel.id);
  }

  @override
  Future<void> deleteTask(String id) async {
    // Mark for deletion
    await _markAsDeleted(id);

    // Delete locally
    await localDataSource.deleteTask(id);
  }

  @override
  Future<List<Task>> getIncompleteTasks() async {
    final tasks = await localDataSource.getAllTasks();
    return tasks.where((task) => task.status != TaskStatus.completed).toList();
  }

  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    return localDataSource.getTasksForDate(date);
  }

  @override
  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate) async {
    return localDataSource.getTasksInDateRange(startDate, endDate);
  }

  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    return localDataSource.getTasksByProject(projectId);
  }

  @override
  Future<void> markTaskAsInProgress(String id) async {
    final task = await localDataSource.getTaskById(id);
    if (task != null) {
      await saveTask(task.markAsInProgress());
    }
  }

  @override
  Future<void> markTaskAsCompleted(String id) async {
    final task = await localDataSource.getTaskById(id);
    if (task != null) {
      await saveTask(task.markAsCompleted());
    }
  }

  @override
  Future<void> incrementTaskPomodoro(String id) async {
    final task = await localDataSource.getTaskById(id);
    if (task != null) {
      await saveTask(task.incrementPomodoro());
    }
  }

  @override
  Future<void> moveTasksToInbox(String fromProjectId) async {
    final tasks = await getTasksByProject(fromProjectId);
    for (final task in tasks) {
      await saveTask(task.copyWith(projectId: 'inbox'));
    }
  }

  // Sync-related methods
  // Mark a task for sync
  Future<void> _markForSync(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? [];

    if (!pendingSyncIds.contains(id)) {
      pendingSyncIds.add(id);
      await prefs.setStringList('pending_task_sync_ids', pendingSyncIds);
    }
  }

  // Mark a task as deleted for sync
  Future<void> _markAsDeleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? [];

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_task_ids', deletedIds);
    }
  }

  // Get pending sync IDs
  Future<Set<String>> _getPendingSyncIds() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? [];
    return pendingSyncIds.toSet();
  }

  // Get deleted IDs
  Future<Set<String>> _getDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? [];
    return deletedIds.toSet();
  }

  // Clear sync markers
  Future<void> _clearSyncMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncIds = prefs.getStringList('pending_task_sync_ids') ?? []
    ..removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('pending_task_sync_ids', pendingSyncIds);
  }

  // Clear deletion markers
  Future<void> _clearDeletionMarkers(Set<String> processedIds) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_task_ids') ?? []
    ..removeWhere((id) => processedIds.contains(id));
    await prefs.setStringList('deleted_task_ids', deletedIds);
  }

  @override
  Future<int> pushChanges() async {
    final pendingSyncIds = await _getPendingSyncIds();
    final deletedIds = await _getDeletedIds();

    if (pendingSyncIds.isEmpty && deletedIds.isEmpty) {
      return 0;
    }

    // Get all tasks as map for quick lookup
    final tasks = await localDataSource.getAllTasks();
    final tasksMap = {for (final task in tasks) task.id: task};

    // Push to remote
    final syncCount = await remoteDataSource.pushChanges(
      pendingSyncIds,
      deletedIds,
      tasksMap,
    );

    // Clear markers for processed IDs
    await _clearSyncMarkers(pendingSyncIds);
    await _clearDeletionMarkers(deletedIds);

    // Update last sync time
    await remoteDataSource.setLastSyncTime(DateTime.now());

    return syncCount;
  }

  @override
  Future<int> pullChanges() async {
    // Get last sync time
    final lastSyncTime = await remoteDataSource.getLastSyncTime();

    // Get deleted IDs to prevent re-adding deleted items
    final deletedIds = await _getDeletedIds();

    // Get pending sync IDs to avoid overwriting local changes
    final pendingSyncIds = await _getPendingSyncIds();

    // Fetch remote changes
    final remoteTasks = await remoteDataSource.pullChanges(lastSyncTime);

    var syncCount = 0;

    // Process each remote task
    for (final remoteTask in remoteTasks) {
      // Skip if task is pending local sync
      if (pendingSyncIds.contains(remoteTask.id)) {
        continue;
      }

      // Skip if task is locally deleted
      if (deletedIds.contains(remoteTask.id)) {
        continue;
      }

      // Get local task
      final localTask = await localDataSource.getTaskById(remoteTask.id);

      // Only update if remote is newer or local doesn't exist
      if (localTask == null || remoteTask.updatedAt > localTask.updatedAt) {
        await localDataSource.saveTask(remoteTask);
        syncCount++;
      }
    }

    // Update last sync time
    await remoteDataSource.setLastSyncTime(DateTime.now());

    return syncCount;
  }

  @override
  Future<bool> hasPendingChanges() async {
    final pendingSyncIds = await _getPendingSyncIds();
    final deletedIds = await _getDeletedIds();
    return pendingSyncIds.isNotEmpty || deletedIds.isNotEmpty;
  }
}
