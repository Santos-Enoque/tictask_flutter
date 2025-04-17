import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetAllTasksUseCase {
  
  GetAllTasksUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<List<Task>> execute() async {
    return _repository.getAllTasks();
  }
}
