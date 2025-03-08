part of 'project_bloc.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  const ProjectLoaded(this.projects);

  final List<Project> projects;

  @override
  List<Object> get props => [projects];
}

class ProjectActionSuccess extends ProjectState {
  const ProjectActionSuccess(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

class ProjectError extends ProjectState {
  const ProjectError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
