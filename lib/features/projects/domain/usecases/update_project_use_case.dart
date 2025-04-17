import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';

class UpdateProjectUseCase {
  final IProjectRepository _repository;
  
  UpdateProjectUseCase(this._repository);
  
  Future<void> execute({
    required String id,
    required String name,
    required int color,
    String? description,
    String? emoji,
  }) async {
    final existingProject = await _repository.getProjectById(id);
    if (existingProject == null) {
      throw Exception('Project not found');
    }
    
    final updatedProject = ProjectModel.fromEntity(existingProject).copyWith(
      name: name,
      description: description,
      color: color,
      emoji: emoji,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _repository.saveProject(updatedProject);
  }
}