
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';

class AddProjectUseCase {
  final IProjectRepository _repository;
  
  AddProjectUseCase(this._repository);
  
  Future<void> execute({
    required String name,
    required int color,
    String? description,
    String? emoji,
  }) async {
    final project = ProjectModel.create(
      name: name,
      color: color,
      description: description,
      emoji: emoji,
    );
    
    await _repository.saveProject(project);
  }
}