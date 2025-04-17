import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class SyncTasksUseCase {
  
  SyncTasksUseCase(this._repository);
  final ITaskRepository _repository;
  
  Future<int> pushChanges() async {
    return _repository.pushChanges();
  }
  
  Future<int> pullChanges() async {
    return _repository.pullChanges();
  }
  
  Future<bool> hasPendingChanges() async {
    return _repository.hasPendingChanges();
  }
}
