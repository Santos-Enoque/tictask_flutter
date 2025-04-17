import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class MarkTaskAsCompletedUseCase {
  
  MarkTaskAsCompletedUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<void> execute(String id) async {
    await _repository.markTaskAsCompleted(id);
  }
}
