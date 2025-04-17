import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class MarkTaskAsInProgress {
  MarkTaskAsInProgress(this.repository);
  final TaskRepository repository;

  Future<void> call(String id) async {
    await repository.markTaskAsInProgress(id);
  }
}
