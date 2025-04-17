import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTasksInDateRangeUseCase {
  
  GetTasksInDateRangeUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<List<Task>> execute(DateTime startDate, DateTime endDate, {String? projectId}) async {
    final tasks = await _repository.getTasksInDateRange(startDate, endDate);
    
    if (projectId != null) {
      return tasks.where((task) => task.projectId == projectId).toList();
    }
    
    return tasks;
  }
}
