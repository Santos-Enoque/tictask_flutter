import 'package:flutter/foundation.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';

/// Interface for project repository
abstract class IProjectRepository {
  /// Get all projects
  Future<List<ProjectEntity>> getAllProjects();
  
  /// Get project by ID
  Future<ProjectEntity?> getProjectById(String id);
  
  /// Save a project (create or update)
  Future<void> saveProject(ProjectEntity project);
  
  /// Delete a project by ID
  Future<void> deleteProject(String id);
}
