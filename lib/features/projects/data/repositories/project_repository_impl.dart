import 'package:tictask/features/projects/data/datasources/project_local_data_source.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';

class ProjectRepositoryImpl implements IProjectRepository {
  final ProjectLocalDataSource _localDataSource;
  
  ProjectRepositoryImpl(this._localDataSource);
  
  Future<void> init() async {
    await _localDataSource.init();
  }
  
  @override
  Future<List<ProjectEntity>> getAllProjects() async {
    return _localDataSource.getAllProjects();
  }
  
  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    return _localDataSource.getProjectById(id);
  }
  
  @override
  Future<void> saveProject(ProjectEntity project) async {
    final projectModel = project is ProjectModel 
        ? project 
        : ProjectModel.fromEntity(project);
    
    await _localDataSource.saveProject(projectModel);
  }
  
  @override
  Future<void> deleteProject(String id) async {
    await _localDataSource.deleteProject(id);
  }
}
