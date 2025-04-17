// lib/features/tasks/data/datasources/task_remote_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<void> saveTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<int> pushChanges(Set<String> pendingSyncIds, Set<String> deletedIds, Map<String, TaskModel> localTasks);
  Future<List<TaskModel>> pullChanges(DateTime? lastSyncTime);
  Future<void> setLastSyncTime(DateTime time);
  Future<DateTime?> getLastSyncTime();
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {

  TaskRemoteDataSourceImpl({
    required this.supabase,
    required this.userId,
  });
  final SupabaseClient supabase;
  final String userId;
  static const String _tableName = 'tasks';
  static const String _lastSyncTimeKey = 'tasks_last_sync_time';

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    final taskMap = task.toJson();
    taskMap['user_id'] = userId;

    await supabase
        .from(_tableName)
        .upsert(taskMap);
  }

  @override
  Future<void> deleteTask(String id) async {
    await supabase
        .from(_tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  @override
  Future<int> pushChanges(
    Set<String> pendingSyncIds,
    Set<String> deletedIds,
    Map<String, TaskModel> localTasks,
  ) async {
    var syncCount = 0;

    // Process updates
    if (pendingSyncIds.isNotEmpty) {
      final syncedIds = <String>{};

      for (final id in pendingSyncIds) {
        final task = localTasks[id];
        if (task != null) {
          // Skip if this task is also marked for deletion
          if (deletedIds.contains(id)) {
            continue;
          }

          // Push to Supabase
          final taskMap = task.toJson();
          taskMap['user_id'] = userId;
          await supabase.from(_tableName).upsert(taskMap);

          syncedIds.add(id);
          syncCount++;
        }
      }
    }

    // Process deletions
    if (deletedIds.isNotEmpty) {
      for (final id in deletedIds) {
        await supabase
            .from(_tableName)
            .delete()
            .eq('id', id)
            .eq('user_id', userId);
        syncCount++;
      }
    }

    return syncCount;
  }

  @override
  Future<List<TaskModel>> pullChanges(DateTime? lastSyncTime) async {
    final timestamp = lastSyncTime?.millisecondsSinceEpoch ?? 0;

    final response = await supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', timestamp);

    return (response as List)
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    final timestamp = prefs.getInt(key);

    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }
}
