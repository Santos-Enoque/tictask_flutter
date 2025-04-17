import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class MoveTasksToInbox {
  MoveTasksToInbox(this.repository);
  final TaskRepository repository;

  Future<void> call(String fromProjectId) async {
    await repository.moveTasksToInbox(fromProjectId);
  }
}
