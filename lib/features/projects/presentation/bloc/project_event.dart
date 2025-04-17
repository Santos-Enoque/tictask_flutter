part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectEvent {
  const LoadProjects();
}

class AddProject extends ProjectEvent {
  const AddProject({
    required this.name,
    required this.color,
    this.description,
    this.emoji,
  });

  final String name;
  final int color;
  final String? description;
  final String? emoji;

  @override
  List<Object?> get props => [name, color, description, emoji];
}

class UpdateProject extends ProjectEvent {
  const UpdateProject({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    this.emoji,
  });

  final String id;
  final String name;
  final int color;
  final String? description;
  final String? emoji;

  @override
  List<Object?> get props => [id, name, color, description, emoji];
}

class DeleteProject extends ProjectEvent {
  const DeleteProject({required this.id});

  final String id;

  @override
  List<Object> get props => [id];
}
