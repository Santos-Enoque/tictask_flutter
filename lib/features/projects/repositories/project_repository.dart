import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictask/features/projects/models/project.dart';

class ProjectRepository {
  static const String _projectsBoxName = 'projects_box';
  late Box<Project> _projectsBox;

  // Initialize repository
  Future<void> init() async {
    try {
      // Register class adapters
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(ProjectAdapter());
      }

      // Open box
      _projectsBox = await Hive.openBox<Project>(_projectsBoxName);

      // Create default Inbox project if it doesn't exist
      if (_projectsBox.isEmpty) {
        await _projectsBox.put('inbox', Project.inbox());
        print('Default Inbox project created');
      }

      print('ProjectRepository initialized successfully');
    } catch (e) {
      print('Error initializing ProjectRepository: $e');
      // Create an empty box as fallback
      _projectsBox = await Hive.openBox<Project>(_projectsBoxName);

      // Ensure default project exists
      if (_projectsBox.get('inbox') == null) {
        await _projectsBox.put('inbox', Project.inbox());
      }
    }
  }

  // Project CRUD operations
  Future<List<Project>> getAllProjects() async {
    return _projectsBox.values.toList();
  }

  Future<Project?> getProjectById(String id) async {
    return _projectsBox.get(id);
  }

  Future<void> saveProject(Project project) async {
    await _projectsBox.put(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    // Don't allow deletion of the default inbox project
    if (id == 'inbox') {
      throw Exception('Cannot delete the default Inbox project');
    }
    await _projectsBox.delete(id);
  }

  // Clean up resources
  Future<void> close() async {
    await _projectsBox.close();
  }
}
