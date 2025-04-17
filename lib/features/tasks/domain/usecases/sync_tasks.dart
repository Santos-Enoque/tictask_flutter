import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class SyncTasks {
  SyncTasks(this.repository);
  final TaskRepository repository;

  Future<bool> hasPendingChanges() async {
    return repository.hasPendingChanges();
  }

  Future<int> pushChanges() async {
    return repository.pushChanges();
  }

  Future<int> pullChanges() async {
    return repository.pullChanges();
  }
}
