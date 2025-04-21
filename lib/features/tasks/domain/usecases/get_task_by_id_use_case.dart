import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTaskByIdUseCase {
  GetTaskByIdUseCase(this._repository);
  final ITaskRepository _repository;

  Future<TaskEntity?> execute(String id) async {
    return _repository.getTaskById(id);
  }
}
