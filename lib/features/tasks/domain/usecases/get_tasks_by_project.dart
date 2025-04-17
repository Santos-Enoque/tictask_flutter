import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class GetTasksByProject {
  GetTasksByProject(this.repository);
  final TaskRepository repository;

  Future<List<Task>> call(String projectId) async {
    return repository.getTasksByProject(projectId);
  }
}
