import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetAllTasksUseCase {
  GetAllTasksUseCase(this._repository);
  final ITaskRepository _repository;

  Future<List<TaskEntity>> execute() async {
    return _repository.getAllTasks();
  }
}
