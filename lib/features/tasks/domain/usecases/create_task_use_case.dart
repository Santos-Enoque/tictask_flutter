import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:uuid/uuid.dart';

class CreateTaskUseCase {
  final ITaskRepository _repository;
  final Uuid _uuid;
  
  CreateTaskUseCase(this._repository, this._uuid);
  
  Future<void> execute({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    int? estimatedPomodoros,
    bool ongoing = false,
    bool hasReminder = false,
    DateTime? reminderTime,
    String projectId = 'inbox',
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      status: TaskStatus.todo,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      pomodorosCompleted: 0,
      estimatedPomodoros: estimatedPomodoros,
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
      ongoing: ongoing,
      hasReminder: hasReminder,
      reminderTime: reminderTime?.millisecondsSinceEpoch,
      projectId: projectId,
    );
    
    await _repository.saveTask(task);
  }
}
