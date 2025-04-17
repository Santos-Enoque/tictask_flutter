import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetIncompleteTasks {
  GetIncompleteTasks(this.repository);
  final TaskRepository repository;

  Future<List<Task>> call() async {
    return repository.getIncompleteTasks();
  }
}
