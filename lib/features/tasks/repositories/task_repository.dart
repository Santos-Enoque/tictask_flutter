import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/tasks/models/task.dart';

class TaskRepository {
  late Box<Task> _tasksBox;

  // Initialize repository
  Future<void> init() async {
    try {
      // Register enum adapter
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(TaskStatusAdapter());
      }

      // Register class adapters
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(TaskAdapter());
      }

      // Open box
      _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBox);

      print('TaskRepository initialized successfully');
    } catch (e) {
      print('Error initializing TaskRepository: $e');
      // Create an empty box as fallback
      _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBox);
    }
  }

  // Task CRUD operations
  Future<List<Task>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  Future<List<Task>> getIncompleteTasks() async {
    return _tasksBox.values
        .where((task) => task.status != TaskStatus.completed)
        .toList();
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
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

  Future<List<Task>> getTasksInDateRange(
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

  Future<Task?> getTaskById(String id) async {
    return _tasksBox.get(id);
  }

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Future<void> markTaskAsInProgress(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.markAsInProgress());
    }
  }

  Future<void> markTaskAsCompleted(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.markAsCompleted());
    }
  }

  Future<void> incrementTaskPomodoro(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.incrementPomodoro());
    }
  }

  // Add method to get tasks by project
  Future<List<Task>> getTasksByProject(String projectId) async {
    return _tasksBox.values
        .where((task) => task.projectId == projectId)
        .toList();
  }

  // Update tasks when a project is deleted (move them to Inbox)
  Future<void> moveTasksToInbox(String fromProjectId) async {
    final tasks = await getTasksByProject(fromProjectId);
    for (final task in tasks) {
      await saveTask(task.copyWith(projectId: 'inbox'));
    }
  }

  // Clean up resources
  Future<void> close() async {
    await _tasksBox.close();
  }
}
