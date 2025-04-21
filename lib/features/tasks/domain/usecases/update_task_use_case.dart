import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class UpdateTaskUseCase {
  final ITaskRepository _repository;
  
  UpdateTaskUseCase(this._repository);
  
  Future<void> execute({
    required String id,
    required String title,
    String? description,
    int? estimatedPomodoros,
    DateTime? startDate,
    DateTime? endDate,
    bool? ongoing,
    bool? hasReminder,
    DateTime? reminderTime,
    String? projectId,
  }) async {
    // First get the existing task
    final existingTask = await _repository.getTaskById(id);
    if (existingTask == null) {
      throw Exception('Task not found');
    }
    
    // Create updated task with new values
    final updatedTask = existingTask.copyWith(
      title: title,
      description: description,
      estimatedPomodoros: estimatedPomodoros,
      startDate: startDate?.millisecondsSinceEpoch,
      endDate: endDate?.millisecondsSinceEpoch,
      ongoing: ongoing,
      hasReminder: hasReminder,
      reminderTime: reminderTime?.millisecondsSinceEpoch,
      projectId: projectId,
    );
    
    await _repository.saveTask(updatedTask);
  }
}
