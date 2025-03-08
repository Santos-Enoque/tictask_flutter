import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc({required ProjectRepository projectRepository})
      : _projectRepository = projectRepository,
        super(ProjectInitial()) {
    on<LoadProjects>(_onLoadProjects);
    on<AddProject>(_onAddProject);
    on<UpdateProject>(_onUpdateProject);
    on<DeleteProject>(_onDeleteProject);
  }

  final ProjectRepository _projectRepository;

  // Expose repository for direct access when needed
  ProjectRepository get repository => _projectRepository;

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final projects = await _projectRepository.getAllProjects();
      emit(ProjectLoaded(projects));
    } catch (e) {
      emit(ProjectError('Failed to load projects: $e'));
    }
  }

  Future<void> _onAddProject(
    AddProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final project = Project.create(
        name: event.name,
        color: event.color,
        description: event.description,
      );
      await _projectRepository.saveProject(project);
      final projects = await _projectRepository.getAllProjects();
      emit(ProjectLoaded(projects));
      emit(const ProjectActionSuccess('Project added successfully'));
    } catch (e) {
      emit(ProjectError('Failed to add project: $e'));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final existingProject = await _projectRepository.getProjectById(event.id);
      if (existingProject == null) {
        emit(const ProjectError('Project not found'));
        return;
      }

      final updatedProject = existingProject.copyWith(
        name: event.name,
        description: event.description,
        color: event.color,
      );

      await _projectRepository.saveProject(updatedProject);
      final projects = await _projectRepository.getAllProjects();
      emit(ProjectLoaded(projects));
      emit(const ProjectActionSuccess('Project updated successfully'));
    } catch (e) {
      emit(ProjectError('Failed to update project: $e'));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProject event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      await _projectRepository.deleteProject(event.id);
      final projects = await _projectRepository.getAllProjects();
      emit(ProjectLoaded(projects));
      emit(const ProjectActionSuccess('Project deleted successfully'));
    } catch (e) {
      emit(ProjectError('Failed to delete project: $e'));
    }
  }
}
