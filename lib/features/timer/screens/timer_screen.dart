import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only do this once per lifecycle
    if (!_hasInitializedTask && widget.autoStart && widget.taskId != null) {
      _hasInitializedTask = true;

      // This is safer to access providers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // First, load the task
        _updateTaskFuture(widget.taskId!);

        // Then start the timer with the task
        context.read<TimerBloc>().add(TimerStarted(taskId: widget.taskId));
      });
    }
  }

  // Update this method to not use setState
  void _updateTaskFuture(String taskId) {
    try {
      final taskRepository = context.read<TaskRepository>();
      _taskFuture = taskRepository.getTaskById(taskId);
      _currentTaskId = taskId;

      // Safely update the state after the task is loaded
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading task: $e');
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
        title: const Text('TicTask Timer'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      drawer: _buildDrawer(context),
      body: BlocConsumer<TimerBloc, TimerState>(
        listener: (context, state) {
          // Update the task data when the timer state changes
          if (state.currentTaskId != null &&
              state.currentTaskId != _currentTaskId) {
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

                  // 2. Current task display or task selection widget
                  const SizedBox(height: AppDimensions.lg),
                  _buildTaskSection(state),

                  // 3. Timer display
                  const SizedBox(height: AppDimensions.lg),
                  Expanded(
                    child: Center(
                      child: TimerDisplay(
                        timeRemaining: state.timeRemaining,
                        progress: state.progress,
                        statusText: statusText,
                        progressColor: statusColor,
                      ),
                    ),
                  ),

                  // 4. Timer controls at the bottom
                  const SizedBox(height: AppDimensions.md),
                  _buildCupertinoTimerControls(context, state),
                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            ),
          );
        },
      ),
      // Only show bottom navigation if showNavBar is true
      bottomNavigationBar: widget.showNavBar
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer),
                  label: 'Timer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_outline),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
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

  // New method to build the task section - either current task or task selector
  Widget _buildTaskSection(TimerState state) {
    // Case 1: We have a task ID and loaded task
    if (state.currentTaskId != null && _taskFuture != null) {
      return FutureBuilder<Task?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            final task = snapshot.data!;
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.md),
              ),
              child: InkWell(
                onTap: _navigateToTaskSelection, // Allow changing the task
                borderRadius: BorderRadius.circular(AppDimensions.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    children: [
                      Text(
                        'Current Task',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Data is null, show task selection button
          return _buildTaskSelectionButton();
        },
      );
    }

    // Case 2: No task selected, show task selection button
    return _buildTaskSelectionButton();
  }

  // Helper method to build the task selection button
  Widget _buildTaskSelectionButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.md),
      ),
      child: InkWell(
        onTap: _navigateToTaskSelection,
        borderRadius: BorderRadius.circular(AppDimensions.md),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            children: [
              const Icon(Icons.add_task, size: 28),
              const SizedBox(height: 4),
              Text(
                'Select a Task',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
