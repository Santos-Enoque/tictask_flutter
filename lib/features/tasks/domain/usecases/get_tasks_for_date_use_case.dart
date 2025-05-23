import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';

class GetTasksForDateUseCase {
  GetTasksForDateUseCase(this._repository);
  final ITaskRepository _repository;

  Future<List<TaskEntity>> execute(DateTime date, {String? projectId}) async {
    final tasks = await _repository.getTasksForDate(date);

    if (projectId != null) {
      return tasks.where((task) => task.projectId == projectId).toList();
    }

    return tasks;
  }
}
