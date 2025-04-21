import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTasksByProjectUseCase {
  GetTasksByProjectUseCase(this._repository);
  final ITaskRepository _repository;

  Future<List<TaskEntity>> execute(String projectId) async {
    return _repository.getTasksByProject(projectId);
  }
}
