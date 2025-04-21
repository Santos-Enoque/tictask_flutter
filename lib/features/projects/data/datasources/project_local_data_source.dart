import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/core/constants/storage_constants.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';

abstract class ProjectLocalDataSource {
  Future<void> init();
  Future<List<ProjectModel>> getAllProjects();
  Future<ProjectModel?> getProjectById(String id);
  Future<void> saveProject(ProjectModel project);
  Future<void> deleteProject(String id);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  late Box<ProjectModel> _projectsBox;

  @override
  Future<void> init() async {
    try {
      // Clear existing box first
      await Hive.deleteBoxFromDisk(StorageConstants.projectsBox);

      // Register class adapters
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(ProjectModelAdapter());
      }

      // Open box
      _projectsBox =
          await Hive.openBox<ProjectModel>(StorageConstants.projectsBox);

      // Create default Inbox project if it doesn't exist
      if (_projectsBox.isEmpty) {
        await _projectsBox.put('inbox', ProjectModel.inbox());
        print('Default Inbox project created');
      }

      print('ProjectLocalDataSource initialized successfully');
    } catch (e) {
      print('Error initializing ProjectLocalDataSource: $e');
      // Create an empty box as fallback
      _projectsBox =
          await Hive.openBox<ProjectModel>(StorageConstants.projectsBox);

      // Ensure default project exists
      if (_projectsBox.get('inbox') == null) {
        await _projectsBox.put('inbox', ProjectModel.inbox());
      }
    }
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    return _projectsBox.values.toList();
  }

  @override
  Future<ProjectModel?> getProjectById(String id) async {
    return _projectsBox.get(id);
  }

  @override
  Future<void> saveProject(ProjectModel project) async {
    await _projectsBox.put(project.id, project);
  }

  @override
  Future<void> deleteProject(String id) async {
    // Don't allow deletion of the default inbox project
    if (id == 'inbox') {
      throw Exception('Cannot delete the default Inbox project');
    }
    await _projectsBox.delete(id);
  }
}
