import 'package:tictask/features/tasks/domain/entities/task.dart';

/// Interface defining task repository operations
abstract class ITaskRepository {
  /// Get all tasks
  Future<List<Task>> getAllTasks();
  
  /// Get task by ID
  Future<Task?> getTaskById(String id);
  
  /// Save a task (create or update)
  Future<void> saveTask(Task task);
  
  /// Delete a task by ID
  Future<void> deleteTask(String id);
  
  /// Get incomplete tasks
  Future<List<Task>> getIncompleteTasks();
  
  /// Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date);
  
  /// Get tasks within a date range
  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate);
  
  /// Get tasks by project
  Future<List<Task>> getTasksByProject(String projectId);
  
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
