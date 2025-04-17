import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int color;
  final int createdAt;
  final int updatedAt;
  final bool isDefault;
  final String? emoji;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isDefault = false,
    this.emoji,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        emoji,
        createdAt,
        updatedAt,
        isDefault,
      ];
}
