import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class TaskRepositoryImpl implements ITaskRepository {
  late Box<TaskModel> _tasksBox;

  // Initialize repository
  Future<void> init() async {
    try {
      // Register enum adapter
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(TaskStatusAdapter());
      }

      // Register class adapters
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(TaskModelAdapter());
      }

      // Open box
      _tasksBox = await Hive.openBox<TaskModel>(AppConstants.tasksBox);

      print('TaskRepositoryImpl initialized successfully');
    } catch (e) {
      print('Error initializing TaskRepositoryImpl: $e');
      // Create an empty box as fallback
      _tasksBox = await Hive.openBox<TaskModel>(AppConstants.tasksBox);
    }
  }

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

  @override
  Future<void> saveTask(TaskEntity task) async {
    // Ensure we have a TaskModel
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

    await _tasksBox.put(task.id, taskModel);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  @override
  Future<void> markTaskAsInProgress(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.markAsInProgress());
    }
  }

  @override
  Future<void> markTaskAsCompleted(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.markAsCompleted());
    }
  }

  @override
  Future<void> incrementTaskPomodoro(String id) async {
    final task = _tasksBox.get(id);
    if (task != null) {
      await _tasksBox.put(id, task.incrementPomodoro());
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

  // Basic implementation of sync-related methods in the non-syncable version
  @override
  Future<int> pushChanges() async {
    // Not supported in basic repository
    return 0;
  }

  @override
  Future<int> pullChanges() async {
    // Not supported in basic repository
    return 0;
  }

  @override
  Future<bool> hasPendingChanges() async {
    // Not supported in basic repository
    return false;
  }

  // Clean up resources
  Future<void> close() async {
    await _tasksBox.close();
  }
}
