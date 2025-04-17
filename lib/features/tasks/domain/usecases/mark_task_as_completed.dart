import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class MarkTaskAsCompleted {
  
  MarkTaskAsCompleted(this.repository);
  final TaskRepository repository;
  
  Future<void> call(String id) async {
    await repository.markTaskAsCompleted(id);
  }
}