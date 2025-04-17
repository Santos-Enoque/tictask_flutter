import 'package:tictask/features/tasks/domain/entities/task.dart';

abstract class TaskRepository {
  // Basic CRUD
  Future<List<Task>> getAllTasks();
  Future<Task?> getTaskById(String id);
  Future<void> saveTask(Task task);
  Future<void> deleteTask(String id);
  
  // Filtered queries
  Future<List<Task>> getIncompleteTasks();
  Future<List<Task>> getTasksForDate(DateTime date);
  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate);
  Future<List<Task>> getTasksByProject(String projectId);
  
  // Task status changes
  Future<void> markTaskAsInProgress(String id);
  Future<void> markTaskAsCompleted(String id);
  Future<void> incrementTaskPomodoro(String id);
  
  // Project-related operations
  Future<void> moveTasksToInbox(String fromProjectId);
  
  // Sync operations
  Future<int> pushChanges();
  Future<int> pullChanges();
  Future<bool> hasPendingChanges();
}
