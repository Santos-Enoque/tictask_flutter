import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/app/widgets/app_scaffold.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/widgets/task_form_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasksByDate(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tasks',
      showBottomNav: widget.showNavBar,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _showIOSDatePicker,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskFormSheet,
        child: const Icon(Icons.add),
      ),
      child: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskLoaded) {
            return _buildTaskList(state.tasks);
          } else {
            return const Center(child: Text('No tasks found'));
          }
        },
      ),
    );
  }

  void _showIOSDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedDate = date;
        });
        if (!mounted) return;
        context.read<TaskBloc>().add(LoadTasksByDate(date));
      }
    });
  }

  void _showTaskFormSheet({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            if (state is TaskActionSuccess) {
              Navigator.of(context).pop();
              context.read<TaskBloc>().add(LoadTasksByDate(_selectedDate));
            } else if (state is TaskError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: TaskFormSheet(
            task: task,
            onComplete: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No tasks for ${dateFormat.format(_selectedDate)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _showTaskFormSheet,
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    // Group tasks by status
    final todoTasks =
        tasks.where((task) => task.status == TaskStatus.todo).toList();
    final inProgressTasks =
        tasks.where((task) => task.status == TaskStatus.inProgress).toList();
    final completedTasks =
        tasks.where((task) => task.status == TaskStatus.completed).toList();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            dateFormat.format(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (inProgressTasks.isNotEmpty) ...[
          _buildTaskSection('In Progress', inProgressTasks),
        ],
        if (todoTasks.isNotEmpty) ...[
          _buildTaskSection('To Do', todoTasks),
        ],
        if (completedTasks.isNotEmpty) ...[
          _buildTaskSection('Completed', completedTasks),
        ],
      ],
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...tasks.map(_buildTaskItem),
        const Divider(),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    final dateFormat = DateFormat('h:mm a');
    final dueDate = DateTime.fromMillisecondsSinceEpoch(task.dueDate);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm'),
                  content:
                      const Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (direction) {
        context.read<TaskBloc>().add(DeleteTask(task.id));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(dueDate)),
                  if (task.estimatedPomodoros != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.pomodorosCompleted}/${task.estimatedPomodoros}',
                    ),
                  ],
                  if (task.ongoing) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: _buildStatusButtons(task),
          onTap: () => _showTaskFormSheet(task: task),
        ),
      ),
    );
  }

  Widget _buildStatusButtons(Task task) {
    if (task.status == TaskStatus.completed) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<TaskBloc>().add(MarkTaskAsInProgress(task.id));
        },
      );
    } else if (task.status == TaskStatus.inProgress) {
      return IconButton(
        icon: const Icon(Icons.check_circle),
        onPressed: () {
          context.read<TaskBloc>().add(MarkTaskAsCompleted(task.id));
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.play_circle),
        onPressed: () {
          context.read<TaskBloc>().add(MarkTaskAsInProgress(task.id));
        },
      );
    }
  }
}
