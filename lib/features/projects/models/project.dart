import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project.g.dart';

@HiveType(typeId: 11)
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.isDefault = false,
  });

  // Factory method to create a new project
  factory Project.create({
    required String name,
    required int color,
    String? description,
    bool isDefault = false,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Project(
      id: const Uuid().v4(),
      name: name,
      description: description,
      color: color,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
    );
  }

  // Factory for creating the default Inbox project
  factory Project.inbox() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Project(
      id: 'inbox',
      name: 'Inbox',
      description: 'Default project for all tasks',
      color: 0xFF4A6572, // Default color
      createdAt: now,
      updatedAt: now,
      isDefault: true,
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final int color;

  @HiveField(4)
  final int createdAt;

  @HiveField(5)
  final int updatedAt;

  @HiveField(6)
  final bool isDefault;

  // Create a copy with updated fields
  Project copyWith({
    String? name,
    String? description,
    int? color,
    int? updatedAt,
    bool? isDefault,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        color,
        createdAt,
        updatedAt,
        isDefault,
      ];
}
