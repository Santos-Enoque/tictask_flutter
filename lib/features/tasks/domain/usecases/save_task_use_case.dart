import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class SaveTaskUseCase {
  SaveTaskUseCase(this._repository);
  final ITaskRepository _repository;

  Future<void> execute(TaskEntity task) async {
    await _repository.saveTask(task);
  }
}
