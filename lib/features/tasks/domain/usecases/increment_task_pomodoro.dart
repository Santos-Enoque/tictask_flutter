import 'package:tictask/features/tasks/domain/repositories/task_repository.dart';

class IncrementTaskPomodoro {
  IncrementTaskPomodoro(this.repository);
  final TaskRepository repository;

  Future<void> call(String id) async {
    await repository.incrementTaskPomodoro(id);
  }
}
