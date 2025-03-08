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
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now().add(const Duration(days: 7)),
  );

  @override
  void initState() {
    super.initState();
    context
        .read<TaskBloc>()
        .add(LoadTasksInRange(_dateRange.start, _dateRange.end));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tasks',
      showBottomNav: widget.showNavBar,
      actions: [
        // Date Range Picker Button
        IconButton(
          icon: const Icon(Icons.date_range),
          tooltip: 'Select Date Range',
          onPressed: _showDateRangePicker,
        ),
        // Add Task Button
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add Task',
          onPressed: _showTaskFormSheet,
        ),
      ],
      child: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TaskActionSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );

            // Reload tasks for the current date range after any successful action
            context
                .read<TaskBloc>()
                .add(LoadTasksInRange(_dateRange.start, _dateRange.end));
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

  Future<void> _showDateRangePicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null && pickedRange != _dateRange) {
      setState(() {
        _dateRange = pickedRange;
      });
      if (!mounted) return;
      context
          .read<TaskBloc>()
          .add(LoadTasksInRange(_dateRange.start, _dateRange.end));
    }
  }

  void _showTaskFormSheet({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskFormSheet(
          task: task,
          onComplete: () {
            // This closure will be called when the user taps the Add/Update button
            // We'll pop the sheet BEFORE dispatching the event to avoid race conditions
            Navigator.of(context).pop();

            // The TaskBloc events will be dispatched from the TaskFormSheet
            // After the sheet is closed, it will reload the tasks for the selected date
            if (task == null) {
              context
                  .read<TaskBloc>()
                  .add(LoadTasksInRange(_dateRange.start, _dateRange.end));
            }
          },
        );
      },
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No tasks found in selected date range'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _showTaskFormSheet,
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final tasksByDate = <DateTime, List<Task>>{};

    for (final task in tasks) {
      final date = DateTime.fromMillisecondsSinceEpoch(task.dueDate);
      // Remove time part for grouping by date
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (!tasksByDate.containsKey(dateOnly)) {
        tasksByDate[dateOnly] = [];
      }
      tasksByDate[dateOnly]!.add(task);
    }

    // Sort dates
    final sortedDates = tasksByDate.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final tasksForDate = tasksByDate[date]!;

        // Group tasks by status
        final todoTasks =
            tasksForDate.where((t) => t.status == TaskStatus.todo).toList();
        final inProgressTasks = tasksForDate
            .where((t) => t.status == TaskStatus.inProgress)
            .toList();
        final completedTasks = tasksForDate
            .where((t) => t.status == TaskStatus.completed)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${tasksForDate.length} task${tasksForDate.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Tasks by status
            if (inProgressTasks.isNotEmpty)
              _buildTaskStatusSection('In Progress', inProgressTasks),
            if (todoTasks.isNotEmpty)
              _buildTaskStatusSection('To Do', todoTasks),
            if (completedTasks.isNotEmpty)
              _buildTaskStatusSection('Completed', completedTasks),

            // Add divider between dates
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildTaskStatusSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(title),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(title),
                    ),
              ),
            ],
          ),
        ),
        ...tasks.map(_buildTaskItem),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.blue;
      case 'To Do':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        child: Row(
          children: [
            // Checkbox for completion
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Checkbox(
                value: task.status == TaskStatus.completed,
                activeColor: _getStatusColor('Completed'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                onChanged: (bool? value) {
                  if (value == true) {
                    context.read<TaskBloc>().add(MarkTaskAsCompleted(task.id));
                  } else {
                    context.read<TaskBloc>().add(MarkTaskAsInProgress(task.id));
                  }
                },
              ),
            ),
            // Task content
            Expanded(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                          const SizedBox(width: 12),
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
                          const SizedBox(width: 12),
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          const Text('Ongoing'),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: task.status != TaskStatus.completed
                    ? IconButton(
                        icon: const Icon(Icons.play_circle),
                        tooltip: 'Start Pomodoro',
                        onPressed: () {
                          context
                              .read<TaskBloc>()
                              .add(MarkTaskAsInProgress(task.id));
                          // TODO: Navigate to timer with this task selected
                        },
                      )
                    : null,
                onTap: () => _showTaskFormSheet(task: task),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
