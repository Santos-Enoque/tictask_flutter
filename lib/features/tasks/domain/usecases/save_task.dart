import 'package:tictask/features/tasks/domain/entities/task.dart';
import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class SaveTask {
  SaveTask(this.repository);
  final TaskRepository repository;
  
  Future<void> call(Task task) async {
    await repository.saveTask(task);
  }
}
