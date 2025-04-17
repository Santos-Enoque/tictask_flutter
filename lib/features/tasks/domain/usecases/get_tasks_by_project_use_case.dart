import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTasksByProjectUseCase {
  
  GetTasksByProjectUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<List<Task>> execute(String projectId) async {
    return _repository.getTasksByProject(projectId);
  }
}
