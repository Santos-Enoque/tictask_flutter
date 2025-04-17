import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';

class DeleteProjectUseCase {
  
  DeleteProjectUseCase(this._repository);
  final IProjectRepository _repository;
  
  Future<void> execute(String id) async {
    await _repository.deleteProject(id);
  }
}
