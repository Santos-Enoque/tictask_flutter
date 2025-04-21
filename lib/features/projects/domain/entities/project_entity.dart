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

  // Factory for creating the default Inbox project
  // factory ProjectEntity.inbox() {
  //   final now = DateTime.now().millisecondsSinceEpoch;
  //   return ProjectEntity(
  //     id: 'inbox',
  //     name: 'Inbox',
  //     description: 'Default project for all tasks',
  //     emoji: '📥', // Mailbox emoji
  //     color: 0xFF4A6572, // Default color
  //     createdAt: now,
  //     updatedAt: now,
  //     isDefault: true,
  //   );
  // }
}
