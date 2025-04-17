
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/usecases/add_project_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/delete_project_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/get_all_projects_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/get_project_by_id_use_case.dart';
import 'package:tictask/features/projects/domain/usecases/update_project_use_case.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetAllProjectsUseCase _getAllProjectsUseCase;
  final GetProjectByIdUseCase _getProjectByIdUseCase;
  final AddProjectUseCase _addProjectUseCase;
  final UpdateProjectUseCase _updateProjectUseCase;
  final DeleteProjectUseCase _deleteProjectUseCase;

  ProjectBloc({
    required GetAllProjectsUseCase getAllProjectsUseCase,
    required GetProjectByIdUseCase getProjectByIdUseCase,
    required AddProjectUseCase addProjectUseCase,
    required UpdateProjectUseCase updateProjectUseCase,
    required DeleteProjectUseCase deleteProjectUseCase,
  })  : _getAllProjectsUseCase = getAllProjectsUseCase,
        _getProjectByIdUseCase = getProjectByIdUseCase,
        _addProjectUseCase = addProjectUseCase,
        _updateProjectUseCase = updateProjectUseCase,
        _deleteProjectUseCase = deleteProjectUseCase,
        super(ProjectInitial()) {
    on<LoadProjects>(_onLoadProjects);
    on<AddProject>(_onAddProject);
    on<UpdateProject>(_onUpdateProject);
    on<DeleteProject>(_onDeleteProject);
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final projects = await _getAllProjectsUseCase.execute();
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
      await _addProjectUseCase.execute(
        name: event.name,
        color: event.color,
        description: event.description,
        emoji: event.emoji,
      );
      final projects = await _getAllProjectsUseCase.execute();
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
      await _updateProjectUseCase.execute(
        id: event.id,
        name: event.name,
        color: event.color,
        description: event.description,
        emoji: event.emoji,
      );
      final projects = await _getAllProjectsUseCase.execute();
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
      await _deleteProjectUseCase.execute(event.id);
      final projects = await _getAllProjectsUseCase.execute();
      emit(ProjectLoaded(projects));
      emit(const ProjectActionSuccess('Project deleted successfully'));
    } catch (e) {
      emit(ProjectError('Failed to delete project: $e'));
    }
  }
}
