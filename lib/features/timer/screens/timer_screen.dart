import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/widgets/widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    this.showNavBar = true,
    this.taskId,
    this.autoStart = false,
  });

  final bool showNavBar;
  final String? taskId;
  final bool autoStart;

  // Static properties to hold pending task info
  static String? _pendingTaskId;
  static bool _pendingAutoStart = false;

  // Static method to set task info before navigation
  static void setPendingTask(String taskId, {bool autoStart = true}) {
    _pendingTaskId = taskId;
    _pendingAutoStart = autoStart;
  }

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Add a field to store the task future
  Future<Task?>? _taskFuture;
  String? _currentTaskId;
  bool _hasInitializedTask = false;

  @override
  void initState() {
    super.initState();

    // Initialize the timer
    context.read<TimerBloc>().add(const TimerInitialized());

    // Schedule a check for the timer state after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Get current timer state after initialization
        final timerState = context.read<TimerBloc>().state;

        // If there's a current task ID in the timer state, load that task
        if (timerState.currentTaskId != null && _currentTaskId == null) {
          _updateTaskFuture(timerState.currentTaskId!);
        }
      }
    });

    // Check for pending task info
    if (TimerScreen._pendingTaskId != null) {
      // Use the taskId from static property
      final taskId = TimerScreen._pendingTaskId;
      final autoStart = TimerScreen._pendingAutoStart;

      // Clear the static properties
      TimerScreen._pendingTaskId = null;
      TimerScreen._pendingAutoStart = false;

      // Wait for the widget to be fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Get the current timer state
          final timerState = context.read<TimerBloc>().state;

          // Only start a new timer if there isn't one already running
          if (timerState.status != TimerUIStatus.running &&
              timerState.status != TimerUIStatus.breakRunning) {
            // First, load the task
            _updateTaskFuture(taskId!);

            // Then start the timer with the task
            context.read<TimerBloc>().add(TimerStarted(taskId: taskId));
          } else {
            // Show a message that a timer is already running
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'A timer is already running. Complete or cancel it before starting a new one.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we have a taskId and autoStart flag and haven't initialized yet
    if (!_hasInitializedTask && widget.taskId != null && widget.autoStart) {
      // Mark as initialized so we don't do this again
      _hasInitializedTask = true;

      // Get the current timer state
      final timerState = context.read<TimerBloc>().state;

      // Only start a new timer if there isn't one already running
      if (timerState.status != TimerUIStatus.running &&
          timerState.status != TimerUIStatus.breakRunning) {
        // This is safer to access providers
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // First, load the task
          _updateTaskFuture(widget.taskId!);

          // Then start the timer with the task
          context.read<TimerBloc>().add(TimerStarted(taskId: widget.taskId));
        });
      } else {
        // Show a message that a timer is already running
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A timer is already running. Complete or cancel it before starting a new one.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    }
  }

  // Update this method to not use setState
  void _updateTaskFuture(String taskId) {
    try {
      print('Loading task with ID: $taskId');
      final taskRepository = context.read<TaskRepository>();
      _taskFuture = taskRepository.getTaskById(taskId);
      _currentTaskId = taskId;

      // Safely update the state after the task is loaded
      if (mounted) {
        setState(() {});
      }

      // Log when task is loaded
      _taskFuture?.then((task) {
        if (task != null) {
          print('Task loaded successfully: ${task.title}');
        } else {
          print('Task not found with ID: $taskId');
        }
      }).catchError((error) {
        print('Error loading task: $error');
      });
    } catch (e) {
      print('Error initializing task load: $e');
    }
  }

  // Navigate to task selection
  void _navigateToTaskSelection() {
    context.push(Routes.tasks).then((selectedTaskId) {
      if (selectedTaskId != null && selectedTaskId is String) {
        _updateTaskFuture(selectedTaskId);
        context.read<TimerBloc>().add(TimerStarted(taskId: selectedTaskId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTaskDropdown(context),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      drawer: _buildDrawer(context),
      body: BlocConsumer<TimerBloc, TimerState>(
        listener: (context, state) {
          // Update the task data when the timer state changes or on initial load
          if (state.currentTaskId != null &&
              (state.currentTaskId != _currentTaskId ||
                  _currentTaskId == null)) {
            _updateTaskFuture(state.currentTaskId!);
          }
        },
        builder: (context, state) {
          // Determine the status text and color based on state
          String statusText;
          Color statusColor;

          if (state.timerMode == TimerMode.focus) {
            statusText = 'Focus Time';
            statusColor = Theme.of(context).colorScheme.primary;
          } else {
            final isLongBreak =
                state.pomodorosCompleted % state.config.longBreakInterval == 0;
            statusText = isLongBreak ? 'Long Break' : 'Short Break';
            statusColor = Theme.of(context).colorScheme.secondary;
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              child: Column(
                children: [
                  // 1. Stats at the top
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatCard(
                        context,
                        'Today',
                        state.todaysPomodoros.toString(),
                        Icons.calendar_today,
                      ),
                      const SizedBox(width: AppDimensions.md),
                      _buildStatCard(
                        context,
                        'Total',
                        state.pomodorosCompleted.toString(),
                        Icons.timer,
                      ),
                    ],
                  ),

                  // Add flexible space to push content toward center
                  const Spacer(),

                  // Timer display
                  Expanded(
                    flex: 8,
                    child: Center(
                      child: TimerDisplay(
                        timeRemaining: state.timeRemaining,
                        progress: state.progress,
                        statusText: statusText,
                        progressColor: statusColor,
                      ),
                    ),
                  ),

                  // Timer controls with better spacing
                  const SizedBox(height: AppDimensions.lg),
                  _buildCupertinoTimerControls(context, state),

                  // Add flexible space at the bottom to push content up
                  const Spacer(flex: 2),
                ],
              ),
            ),
          );
        },
      ),
      // Only show bottom navigation if showNavBar is true
      bottomNavigationBar: widget.showNavBar
          ? BottomNavigationBar(
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.timer),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.checkCircle),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(LucideIcons.settings),
                  label: '',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Navigate to timer
                    context.push(Routes.timer);
                  case 1:
                    // Navigate to tasks
                    context.push(Routes.tasks);
                  case 2:
                    // Navigate to settings
                    context.push(Routes.settings);
                }
              },
            )
          : null,
    );
  }

  // New method to build iOS-style task dropdown in app bar
  Widget _buildTaskDropdown(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        // Check if timer is running or in break mode
        final isTimerActive = state.status == TimerUIStatus.running ||
            state.status == TimerUIStatus.breakRunning ||
            state.status == TimerUIStatus.paused;

        return GestureDetector(
          // Disable the gesture detector if timer is active
          onTap: isTimerActive ? null : () => _showTaskSelectionModal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(
                    isTimerActive ? 0.2 : 0.3,
                  ), // Dim the container if disabled
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              // Add a subtle border when disabled
              border: isTimerActive
                  ? Border.all(
                      color: Theme.of(context).disabledColor.withOpacity(0.3),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.currentTaskId != null && _taskFuture != null)
                  Flexible(
                    child: FutureBuilder<Task?>(
                      future: _taskFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  // Apply disabled style if timer is active
                                  color: isTimerActive
                                      ? Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.color
                                          ?.withOpacity(0.7)
                                      : null,
                                ),
                            overflow: TextOverflow.ellipsis,
                          );
                        }

                        return Text(
                          'Select Task',
                          style: TextStyle(
                            // Apply disabled style if timer is active
                            color: isTimerActive
                                ? Theme.of(context).disabledColor
                                : null,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Text(
                    'Select Task',
                    style: TextStyle(
                      // Apply disabled style if timer is active
                      color: isTimerActive
                          ? Theme.of(context).disabledColor
                          : null,
                    ),
                  ),
                const SizedBox(width: AppDimensions.xs),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  // Apply disabled style if timer is active
                  color: isTimerActive ? Theme.of(context).disabledColor : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to show task selection modal with todo tasks
  Future<void> _showTaskSelectionModal(BuildContext context) async {
    // Check if timer is active
    final timerState = context.read<TimerBloc>().state;
    final isTimerActive = timerState.status == TimerUIStatus.running ||
        timerState.status == TimerUIStatus.breakRunning ||
        timerState.status == TimerUIStatus.paused;

    // Don't show the modal if the timer is active
    if (isTimerActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot change task while timer is running. Complete or cancel the current timer first.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final taskRepository = context.read<TaskRepository>();

    // Get today's tasks with todo status
    final today = DateTime.now();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get tasks for today
      final allTasks = await taskRepository.getTasksForDate(today);

      // Filter for todo tasks
      final tasks =
          allTasks.where((task) => task.status == TaskStatus.todo).toList();

      // Dismiss loading dialog
      Navigator.of(context).pop();

      if (tasks.isEmpty) {
        // Show message if no tasks
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Tasks'),
            content: const Text(
              'No todo tasks found for today. Would you like to create one?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(Routes.tasks);
                },
                child: const Text('Create Task'),
              ),
            ],
          ),
        );
        return;
      }

      // Show task selection bottom sheet
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                'Select a Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.description ?? ''),
                    leading: const Icon(Icons.task_alt),
                    onTap: () {
                      Navigator.of(context).pop();
                      _updateTaskFuture(task.id);
                      context
                          .read<TimerBloc>()
                          .add(TimerStarted(taskId: task.id));
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(Routes.tasks);
                  },
                  child: const Text('Create New Task'),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TicTask',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Focus. Complete. Repeat.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Timer'),
            onTap: () {
              context.push(Routes.timer);
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Tasks'),
            onTap: () {
              context.push(Routes.tasks);
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              context.push(Routes.settings);
              Navigator.pop(context); // Close drawer
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Show about dialog
              showAboutDialog(
                context: context,
                applicationName: 'TicTask',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 TicTask',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A Pomodoro timer app to help you stay focused and productive.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoTimerControls(BuildContext context, TimerState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    if (state.status == TimerUIStatus.initial) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () => context.read<TimerBloc>().add(const TimerStarted()),
        icon: const Icon(Icons.play_arrow),
        label: const Text(
          'Start Focus',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (state.status == TimerUIStatus.running) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: secondaryColor,
            onPressed: () => context.read<TimerBloc>().add(const TimerPaused()),
            child: const Icon(
              Icons.pause,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
            child: const Icon(
              Icons.refresh,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    if (state.status == TimerUIStatus.paused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () =>
                context.read<TimerBloc>().add(const TimerResumed()),
            child: const Icon(
              Icons.play_arrow,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
            child: const Icon(
              Icons.refresh,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    if (state.status == TimerUIStatus.finished ||
        state.status == TimerUIStatus.breakReady) {
      // Focus ended, show break options
      if (state.timerMode == TimerMode.focus) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () =>
                  context.read<TimerBloc>().add(const TimerBreakStarted()),
              icon: const Icon(Icons.coffee),
              label: const Text(
                'Take a Break',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () =>
                  context.read<TimerBloc>().add(const TimerStarted()),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Continue Focus',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      } else {
        // Break ended
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () =>
                  context.read<TimerBloc>().add(const TimerBreakSkipped()),
              icon: const Icon(Icons.work),
              label: const Text(
                'Start Focus',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () =>
                  context.read<TimerBloc>().add(const TimerBreakStarted()),
              icon: const Icon(Icons.coffee),
              label: const Text(
                'More Break Time',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }
    }

    // For break running or any other state, show appropriate controls
    if (state.status == TimerUIStatus.breakRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            backgroundColor: secondaryColor,
            onPressed: () => context.read<TimerBloc>().add(const TimerPaused()),
            child: const Icon(
              Icons.pause,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
            child: const Icon(
              Icons.refresh,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    // Fallback for other states
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: () => context.read<TimerBloc>().add(const TimerStarted()),
      icon: const Icon(Icons.play_arrow),
      label: const Text(
        'Start Focus',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).colorScheme.surface,
      //   borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      //   border: Border.all(
      //     color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      //   ),
      // ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
