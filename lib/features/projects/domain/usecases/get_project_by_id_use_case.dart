import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';

class GetProjectByIdUseCase {
  
  GetProjectByIdUseCase(this._repository);
  final IProjectRepository _repository;
  
  Future<ProjectEntity?> execute(String id) async {
    return _repository.getProjectById(id);
  }
}
