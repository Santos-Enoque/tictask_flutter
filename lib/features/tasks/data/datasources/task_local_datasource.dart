// lib/features/tasks/data/datasources/task_local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/core/constants/storage_constants.dart';
import 'package:tictask/features/tasks/data/models/task_model.dart';
abstract class TaskLocalDataSource {
  Future<void> init();
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<void> saveTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> getTasksForDate(DateTime date);
  Future<List<TaskModel>> getTasksInDateRange(DateTime startDate, DateTime endDate);
  Future<List<TaskModel>> getTasksByProject(String projectId);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  late Box<TaskModel> _tasksBox;

  @override
  Future<void> init() async {
    // Register TaskStatus adapter if not registered
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(TaskStatusAdapter());
    }

    // Register TaskModel adapter if not registered
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    // Open tasks box
    _tasksBox = await Hive.openBox<TaskModel>(StorageConstants.tasksBox);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    return _tasksBox.values.toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    return _tasksBox.get(id);
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    await _tasksBox.put(task.id, task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  @override
  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

    return _tasksBox.values.where((task) {
      // Include ongoing tasks or tasks with date range overlapping this day
      return task.ongoing ||
          (task.startDate <= endOfDay && task.endDate >= startOfDay);
    }).toList();
  }

  @override
  Future<List<TaskModel>> getTasksInDateRange(DateTime startDate, DateTime endDate) async {
    final rangeStart = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
    final rangeEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;

    return _tasksBox.values.where((task) {
      // Include ongoing tasks or tasks with date range overlapping the given range
      return task.ongoing ||
          (task.startDate <= rangeEnd && task.endDate >= rangeStart);
    }).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    return _tasksBox.values.where((task) => task.projectId == projectId).toList();
  }
}
