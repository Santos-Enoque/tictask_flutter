import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';

class GetAllProjectsUseCase {
  
  GetAllProjectsUseCase(this._repository);
  final IProjectRepository _repository;
  
  Future<List<ProjectEntity>> execute() async {
    return _repository.getAllProjects();
  }
}
