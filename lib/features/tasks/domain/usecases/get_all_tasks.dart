import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetAllTasks {
  GetAllTasks(this.repository);
  final TaskRepository repository;

  Future<List<Task>> call() async {
    return repository.getAllTasks();
  }
}
