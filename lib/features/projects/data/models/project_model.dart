
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:uuid/uuid.dart';

part 'project_model.g.dart';

@HiveType(typeId: 11)
class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.emoji,
    super.isDefault = false,
  });

  // Factory method to create a new project
  factory ProjectModel.create({
    required String name,
    required int color,
    String? description,
    String? emoji,
    bool isDefault = false,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProjectModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      emoji: emoji,
      color: color,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
    );
  }

  // Factory for creating the default Inbox project
  factory ProjectModel.inbox() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ProjectModel(
      id: 'inbox',
      name: 'Inbox',
      description: 'Default project for all tasks',
      emoji: '📥', // Mailbox emoji
      color: 0xFF4A6572, // Default color
      createdAt: now,
      updatedAt: now,
      isDefault: true,
    );
  }

  // Create from entity
  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      emoji: entity.emoji,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDefault: entity.isDefault,
    );
  }

  // Create a copy with updated fields
  ProjectModel copyWith({
    String? name,
    String? description,
    int? color,
    int? updatedAt,
    bool? isDefault,
    String? emoji,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      isDefault: isDefault ?? this.isDefault,
    );
  }
  
  // Convert to map for API
  Map<String, dynamic> toJson({String? userId}) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'emoji': emoji,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_default': isDefault,
      'user_id': userId,
    };
  }

  // Create from map from API
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as int,
      emoji: json['emoji'] as String?,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
      isDefault: json['is_default'] as bool,
    );
  }
}
