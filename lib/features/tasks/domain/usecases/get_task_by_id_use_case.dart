import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTaskByIdUseCase {
  
  GetTaskByIdUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<Task?> execute(String id) async {
    return _repository.getTaskById(id);
  }
}
