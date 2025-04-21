import 'package:tictask/features/tasks/domain/entities/task_entity.dart';

/// Interface defining task repository operations
abstract class ITaskRepository {
  /// Get all tasks
  Future<List<TaskEntity>> getAllTasks();

  /// Get task by ID
  Future<TaskEntity?> getTaskById(String id);

  /// Save a task (create or update)
  Future<void> saveTask(TaskEntity task);

  /// Delete a task by ID
  Future<void> deleteTask(String id);

  /// Get incomplete tasks
  Future<List<TaskEntity>> getIncompleteTasks();

  /// Get tasks for a specific date
  Future<List<TaskEntity>> getTasksForDate(DateTime date);

  /// Get tasks within a date range
  Future<List<TaskEntity>> getTasksInDateRange(
      DateTime startDate, DateTime endDate);

  /// Get tasks by project
  Future<List<TaskEntity>> getTasksByProject(String projectId);

  /// Mark task as in progress
  Future<void> markTaskAsInProgress(String id);

  /// Mark task as completed
  Future<void> markTaskAsCompleted(String id);

  /// Increment task pomodoro count
  Future<void> incrementTaskPomodoro(String id);

  /// Move all tasks from a project to Inbox
  Future<void> moveTasksToInbox(String fromProjectId);

  /// Push local changes to remote
  Future<int> pushChanges();

  /// Pull remote changes to local
  Future<int> pullChanges();

  /// Check if repository has pending changes
  Future<bool> hasPendingChanges();
}
