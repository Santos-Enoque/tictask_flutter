
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/presentation/bloc/project_bloc.dart';
import 'package:tictask/features/projects/presentation/widgets/project_form_widget.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    // Load projects when screen initializes
    context.read<ProjectBloc>().add(const LoadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Project',
            onPressed: () => _showCreateProjectModal(context),
          ),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ProjectActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProjectLoaded) {
            return _buildProjectList(context, state.projects);
          } else {
            return const Center(child: Text('No projects found'));
          }
        },
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List<ProjectEntity> projects) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No projects yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateProjectModal(context),
              child: const Text('Create Project'),
            ),
          ],
        ),
      );
    }

    // Separate Inbox from other projects
    ProjectEntity? inboxProject;
    final otherProjects = <ProjectEntity>[];

    for (final project in projects) {
      if (project.id == 'inbox') {
        inboxProject = project;
      } else {
        otherProjects.add(project);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.md),
      children: [
        // Always show Inbox first if it exists
        if (inboxProject != null)
          _buildProjectItem(context, inboxProject, isInbox: true),

        // Then show all other projects
        ...otherProjects.map(
          (project) => _buildProjectItem(context, project),
        ),
      ],
    );
  }

  Widget _buildProjectItem(
    BuildContext context,
    ProjectEntity project, {
    bool isInbox = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: ListTile(
        leading: project.emoji != null && project.emoji!.isNotEmpty
            ? Text(project.emoji!, style: const TextStyle(fontSize: 24))
            : const Icon(Icons.folder_outlined),
        title: Text(project.name),
        subtitle: project.description != null && project.description!.isNotEmpty
            ? Text(
                project.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Project color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(project.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Only show menu for non-inbox projects
            if (!isInbox)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditProjectModal(context, project);
                  } else if (value == 'delete') {
                    _showDeleteProjectConfirmation(context, project);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        onTap: () {
          // Navigate to tasks filtered by this project
          context.go('${Routes.tasks}?projectId=${project.id}');
        },
      ),
    );
  }

  void _showCreateProjectModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProjectFormWidget(
          onComplete: () {
            Navigator.pop(context);
            context.read<ProjectBloc>().add(const LoadProjects());
          },
        );
      },
    );
  }

  void _showEditProjectModal(BuildContext context, ProjectEntity project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProjectFormWidget(
          project: project,
          onComplete: () {
            Navigator.pop(context);
            context.read<ProjectBloc>().add(const LoadProjects());
          },
        );
      },
    );
  }

  void _showDeleteProjectConfirmation(BuildContext context, ProjectEntity project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<ProjectBloc>().add(DeleteProject(id: project.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}