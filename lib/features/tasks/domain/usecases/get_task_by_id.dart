import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetTaskById {
  GetTaskById(this.repository);
  final TaskRepository repository;

  Future<Task?> call(String id) async {
    return repository.getTaskById(id);
  }
}
