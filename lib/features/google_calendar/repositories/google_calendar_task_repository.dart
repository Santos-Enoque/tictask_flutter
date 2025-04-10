import 'package:flutter/foundation.dart';
import 'package:tictask/features/google_calendar/services/task_sync_service.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';


/// A task repository decorator that automatically syncs tasks with Google Calendar
class GoogleCalendarTaskRepository extends TaskRepository {
  final TaskRepository _baseRepository;
  final TaskSyncService _syncService;
  
  GoogleCalendarTaskRepository(this._baseRepository, this._syncService);
  
  @override
  Future<void> init() async {
    await _baseRepository.init();
  }
  
  @override
  Future<List<Task>> getAllTasks() async {
    return _baseRepository.getAllTasks();
  }
  
  @override
  Future<List<Task>> getIncompleteTasks() async {
    return _baseRepository.getIncompleteTasks();
  }
  
  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    return _baseRepository.getTasksForDate(date);
  }
  
  @override
  Future<List<Task>> getTasksInDateRange(DateTime startDate, DateTime endDate) async {
    return _baseRepository.getTasksInDateRange(startDate, endDate);
  }
  
  @override
  Future<Task?> getTaskById(String id) async {
    return _baseRepository.getTaskById(id);
  }
  
  @override
  Future<void> saveTask(Task task) async {
    // First save the task in the base repository
    await _baseRepository.saveTask(task);
    
    // Then sync with Google Calendar
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        _syncService.syncTask(task);
      }
    } catch (e) {
      debugPrint('Error syncing task with Google Calendar: $e');
      // We don't want to fail the save operation if sync fails
    }
  }
  
  @override
  Future<void> deleteTask(String id) async {
    // First attempt to delete the task from Google Calendar
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        await _syncService.deleteTaskEvent(id);
      }
    } catch (e) {
      debugPrint('Error deleting task event from Google Calendar: $e');
      // We don't want to fail the delete operation if sync fails
    }
    
    // Then delete from the base repository
    await _baseRepository.deleteTask(id);
  }
  
  @override
  Future<void> markTaskAsInProgress(String id) async {
    await _baseRepository.markTaskAsInProgress(id);
    
    // Sync the updated task
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        final task = await getTaskById(id);
        if (task != null) {
          await _syncService.syncTask(task);
        }
      }
    } catch (e) {
      debugPrint('Error syncing task status with Google Calendar: $e');
    }
  }
  
  @override
  Future<void> markTaskAsCompleted(String id) async {
    await _baseRepository.markTaskAsCompleted(id);
    
    // Sync the updated task
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        final task = await getTaskById(id);
        if (task != null) {
          await _syncService.syncTask(task);
        }
      }
    } catch (e) {
      debugPrint('Error syncing task status with Google Calendar: $e');
    }
  }
  
  @override
  Future<void> incrementTaskPomodoro(String id) async {
    await _baseRepository.incrementTaskPomodoro(id);
    
    // Sync the updated task
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        final task = await getTaskById(id);
        if (task != null) {
          await _syncService.syncTask(task);
        }
      }
    } catch (e) {
      debugPrint('Error syncing task pomodoro count with Google Calendar: $e');
    }
  }
  
  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    return _baseRepository.getTasksByProject(projectId);
  }
  
  @override
  Future<void> moveTasksToInbox(String fromProjectId) async {
    await _baseRepository.moveTasksToInbox(fromProjectId);
    
    // Sync all affected tasks
    try {
      final syncEnabled = await _syncService.isSyncEnabled();
      if (syncEnabled) {
        final tasks = await getTasksByProject('inbox');
        for (final task in tasks) {
          await _syncService.syncTask(task);
        }
      }
    } catch (e) {
      debugPrint('Error syncing moved tasks with Google Calendar: $e');
    }
  }
  
  @override
  Future<void> close() async {
    await _baseRepository.close();
  }
  
  // Additional methods for Google Calendar integration
  
  /// Performs a full sync of all tasks with Google Calendar
  Future<int> syncAllTasksWithCalendar() async {
    try {
      return await _syncService.syncAllTasks();
    } catch (e) {
      debugPrint('Error performing full sync with Google Calendar: $e');
      return 0;
    }
  }
  
  /// Imports events from Google Calendar as tasks
  Future<int> importEventsFromCalendar({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      return await _syncService.importEventsFromCalendar(
        from: from,
        to: to,
      );
    } catch (e) {
      debugPrint('Error importing events from Google Calendar: $e');
      return 0;
    }
  }
}