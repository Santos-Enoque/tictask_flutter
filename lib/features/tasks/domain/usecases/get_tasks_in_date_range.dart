import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetTasksInDateRange {
  GetTasksInDateRange(this.repository);
  final TaskRepository repository;

  Future<List<Task>> call(DateTime startDate, DateTime endDate) async {
    return repository.getTasksInDateRange(startDate, endDate);
  }
}
