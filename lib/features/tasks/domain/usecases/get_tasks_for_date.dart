import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetTasksForDate {
  GetTasksForDate(this.repository);
  final TaskRepository repository;

  Future<List<Task>> call(DateTime date, {String? projectId}) async {
    final tasks = await repository.getTasksForDate(date);
    
    if (projectId != null) {
      return tasks.where((task) => task.projectId == projectId).toList();
    }
    
    return tasks;
  }
}
