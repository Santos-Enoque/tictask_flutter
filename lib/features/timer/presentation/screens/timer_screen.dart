
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/core/services/window_service.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';
import 'package:tictask/features/projects/presentation/widgets/project_form_widget.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:tictask/features/timer/domain/entities/timer_entity.dart';
import 'package:tictask/features/timer/presentation/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/presentation/widgets/timer_display.dart';
import 'package:tictask/injection_container.dart';

enum TimerDisplayMode {
  normal, // Regular display with all UI elements
  fullscreen, // Full-screen mode with only timer and controls
  focus // Small floating window with timer and controls
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    super.key,
    this.showNavBar = true,
    this.taskId,
    this.autoStart = false,
    this.onDisplayModeChanged,
  });

  final bool showNavBar;
  final String? taskId;
  final bool autoStart;
  final void Function(TimerDisplayMode)? onDisplayModeChanged;

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
  Future<TaskEntity?>? _taskFuture;
  String? _currentTaskId;
  bool _hasInitializedTask = false;
  late ITaskRepository _taskRepository;
  String? _selectedTaskId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this state variable to track when to reload projects
  int _projectsRefreshCounter = 0;

  // New variables for display modes
  TimerDisplayMode _displayMode = TimerDisplayMode.normal;
  bool _wasResizableBefore = false; // Store previous resizable state
  Size? _previousWindowSize; // Store previous window size

  // Track if we've entered focus mode
  bool _inFocusMode = false;

  @override
  void initState() {
    super.initState();
    _taskRepository = GetIt.I<ITaskRepository>();

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

  @override
  void dispose() {
    // If we were in full-screen or focus mode, restore the previous window state
    _exitSpecialModes();
    super.dispose();
  }

  // Update this method to not use setState
  void _updateTaskFuture(String taskId) {
    try {
      final taskRepository = GetIt.I<ITaskRepository>();
      _taskFuture = taskRepository.getTaskById(taskId);
      _currentTaskId = taskId;

      // Safely update the state after the task is loaded
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing task load: $e');
    }
  }

  // Toggle full-screen mode
  Future<void> _toggleFullScreen() async {
    if (_displayMode != TimerDisplayMode.fullscreen) {
      // Store current window state before going fullscreen
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Store previous resizable state
        final prefs = await SharedPreferences.getInstance();
        _wasResizableBefore =
            prefs.getBool(WindowService.windowResizableKey) ?? false;

        // Get current window size
        if (_previousWindowSize == null) {
          final width = prefs.getDouble(WindowService.windowWidthKey) ??
              WindowService.defaultWindowSize.width;
          final height = prefs.getDouble(WindowService.windowHeightKey) ??
              WindowService.defaultWindowSize.height;
          _previousWindowSize = Size(width, height);
        }

        // Enable resizing and then make it fullscreen
        await WindowService.setResizable(true);
        await WindowService.windowManager.setFullScreen(true);
      }

      setState(() {
        _displayMode = TimerDisplayMode.fullscreen;
      });
      widget.onDisplayModeChanged?.call(_displayMode);
    } else {
      // Exit fullscreen
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        await WindowService.windowManager.setFullScreen(false);

        // Restore original size and position
        if (_previousWindowSize != null) {
          await WindowService.setWindowSize(_previousWindowSize!);
          await WindowService.centerWindow();
        }

        // Restore original resizable state
        await WindowService.setResizable(_wasResizableBefore);
      }

      setState(() {
        _displayMode = TimerDisplayMode.normal;
      });
      widget.onDisplayModeChanged?.call(_displayMode);
    }
  }

  // Toggle focus mode
  Future<void> _toggleFocusMode() async {
    if (_displayMode != TimerDisplayMode.focus) {
      // Store current window state before entering focus mode
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // Store previous resizable state
        final prefs = await SharedPreferences.getInstance();
        _wasResizableBefore =
            prefs.getBool(WindowService.windowResizableKey) ?? false;

        // Get current window size
        if (_previousWindowSize == null) {
          final width = prefs.getDouble(WindowService.windowWidthKey) ??
              WindowService.defaultWindowSize.width;
          final height = prefs.getDouble(WindowService.windowHeightKey) ??
              WindowService.defaultWindowSize.height;
          _previousWindowSize = Size(width, height);
        }

        // Enable window configuration for focus mode
        await WindowService.setResizable(true);
        await WindowService.setAlwaysOnTop(true);

        // Set to a small floating window
        final focusSize = WindowService.focusModeSize;
        await WindowService.setWindowSize(focusSize);

        // Set flag to indicate we're in focus mode
        _inFocusMode = true;
      }

      setState(() {
        _displayMode = TimerDisplayMode.focus;
      });
      widget.onDisplayModeChanged?.call(_displayMode);
    } else {
      // Exit focus mode
      await _exitFocusMode();
    }
  }

  // Exit focus mode
  Future<void> _exitFocusMode() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
        _inFocusMode) {
      // Restore original size and position
      if (_previousWindowSize != null) {
        await WindowService.setWindowSize(_previousWindowSize!);
        await WindowService.centerWindow();
      }

      // Restore original window properties
      await WindowService.setAlwaysOnTop(false);
      await WindowService.setResizable(_wasResizableBefore);

      // Reset focus mode flag
      _inFocusMode = false;
    }

    setState(() {
      _displayMode = TimerDisplayMode.normal;
    });
    widget.onDisplayModeChanged?.call(_displayMode);
  }

  // Exit any special modes (called when disposing)
  Future<void> _exitSpecialModes() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Exit fullscreen if needed
      if (_displayMode == TimerDisplayMode.fullscreen) {
        await WindowService.windowManager.setFullScreen(false);
      }

      // Exit focus mode if needed
      if (_displayMode == TimerDisplayMode.focus) {
        await _exitFocusMode();
      }

      // Restore original size and position if we stored it
      if (_previousWindowSize != null) {
        await WindowService.setWindowSize(_previousWindowSize!);
        await WindowService.centerWindow();
      }

      // Restore original resizable state
      await WindowService.setResizable(_wasResizableBefore);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use different scaffold based on the display mode
    if (_displayMode == TimerDisplayMode.fullscreen) {
      return _buildFullScreenView();
    } else if (_displayMode == TimerDisplayMode.focus) {
      return _buildFocusView();
    } else {
      return _buildNormalView();
    }
  }

  // Build the regular timer view with all UI elements
  Widget _buildNormalView() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _buildTaskDropdown(context),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Projects',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: _buildProjectsDrawer(context),
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

                  // 2. Display mode buttons
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Focus mode button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_in_picture_alt),
                        label: const Text('Focus Mode'),
                        onPressed: _toggleFocusMode,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      // Fullscreen button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Full Screen'),
                        onPressed: _toggleFullScreen,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
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
      // Only show bottom navigation if showNavBar is true and display mode is normal
      bottomNavigationBar:
          widget.showNavBar && _displayMode == TimerDisplayMode.normal
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

  // Build fullscreen view with minimal UI
  Widget _buildFullScreenView() {
    return Scaffold(
      body: BlocBuilder<TimerBloc, TimerState>(
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

          return Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Task name if available
                    if (_currentTaskId != null)
                      FutureBuilder<TaskEntity?>(
                        future: _taskFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                snapshot.data!.title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                    // Large timer display
                    TimerDisplay(
                      timeRemaining: state.timeRemaining,
                      progress: state.progress,
                      statusText: statusText,
                      progressColor: statusColor,
                      large: true,
                    ),

                    const SizedBox(height: 40),

                    // Timer controls
                    _buildCupertinoTimerControls(context, state),
                  ],
                ),
              ),

              // Exit button in top-right corner
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fullscreen_exit),
                  label: const Text('Exit Full Screen'),
                  onPressed: _toggleFullScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build focus view (small and minimal)
  Widget _buildFocusView() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: BlocBuilder<TimerBloc, TimerState>(
        builder: (context, state) {
          // Determine status text and color
          String statusText;
          Color statusColor;

          if (state.timerMode == TimerMode.focus) {
            statusText = 'Focus';
            statusColor = Theme.of(context).colorScheme.primary;
          } else {
            final isLongBreak =
                state.pomodorosCompleted % state.config.longBreakInterval == 0;
            statusText = isLongBreak ? 'Long Break' : 'Break';
            statusColor = Theme.of(context).colorScheme.secondary;
          }

          return Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Compact timer display
                    TimerDisplay(
                      timeRemaining: state.timeRemaining,
                      progress: state.progress,
                      statusText: statusText,
                      progressColor: statusColor,
                      compact: true,
                    ),

                    const SizedBox(height: 16),

                    // Compact timer controls
                    _buildCompactTimerControls(context, state),
                  ],
                ),
              ),

              // Exit button
              Positioned(
                top: 8,
                right: 8,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Exit', style: TextStyle(fontSize: 12)),
                  onPressed: _toggleFocusMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(60, 30),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Replace _buildTaskDropdown method with this
  Widget _buildTaskDropdown(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        // Check if timer is running or in break mode
        final isTimerActive = state.status == TimerUIStatus.running ||
            state.status == TimerUIStatus.breakRunning ||
            state.status == TimerUIStatus.paused;

        if (isTimerActive &&
            _taskFuture != null &&
            state.currentTaskId != null) {
          // Show current task when timer is active
          return FutureBuilder<TaskEntity?>(
            future: _taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                return Text(
                  snapshot.data!.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                );
              }

              return const Text('No Task Selected');
            },
          );
        }

        // Show dropdown when timer is not active
        return FutureBuilder<List<TaskEntity>>(
          future: Future.value(
            _taskRepository.getAllTasks().then(
              (tasks) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final tomorrow = today.add(const Duration(days: 1));

                return tasks.where((task) {
                  // Include task if:
                  // 1. It's not completed AND
                  // 2. Either it's ongoing OR it's scheduled for today
                  if (task.status == TaskStatus.completed) return false;

                  if (task.ongoing) return true;

                  final taskDate =
                      DateTime.fromMillisecondsSinceEpoch(task.startDate);
                  return taskDate.isAfter(today) && taskDate.isBefore(tomorrow);
                }).toList();
              },
            ),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Loading...');
            }

            final tasks = snapshot.data!;
            return DropdownButton<String>(
              value: _selectedTaskId ?? state.currentTaskId,
              hint: const Text('Select Task'),
              underline: Container(),
              items: [
                const DropdownMenuItem<String>(
                  child: Text('No Task'),
                ),
                ...tasks.map(
                  (task) => DropdownMenuItem<String>(
                    value: task.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.task_alt, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (String? newValue) async {
                if (newValue == _selectedTaskId) return;

                // Mark task as in progress
                if (newValue != null) {
                  await _taskRepository.markTaskAsInProgress(newValue);
                  context.read<TaskBloc>().add(const LoadTasks());

                  // Update UI and prepare timer
                  setState(() {
                    _selectedTaskId = newValue;
                    _updateTaskFuture(newValue);
                  });

                  // Set pending task
                  TimerScreen.setPendingTask(newValue);
                } else {
                  setState(() {
                    _selectedTaskId = null;
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  // New simplified drawer with only projects
  Widget _buildProjectsDrawer(BuildContext context) {
    final projectRepository = GetIt.I<IProjectRepository>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with title and add button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Project',
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateProjectModal(context);
                    },
                  ),
                ],
              ),
            ),

            // Projects list with Inbox at top
            Expanded(
              child: FutureBuilder<List<ProjectEntity>>(
                key: ValueKey('projects-$_projectsRefreshCounter'),
                future: Future(() async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  return projectRepository.getAllProjects();
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No projects found'),
                    );
                  }

                  final projects = snapshot.data!;

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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New helper method to build project items with popup menu
  Widget _buildProjectItem(
    BuildContext context,
    ProjectEntity project, {
    bool isInbox = false,
  }) {
    return ListTile(
      leading: project.emoji != null && project.emoji!.isNotEmpty
          ? Text(project.emoji!, style: const TextStyle(fontSize: 24))
          : const Icon(Icons.folder_outlined),
      title: Text(project.name),
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

          // Only show menu for non-inbox projects
          if (!isInbox)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  // Show edit project modal
                  Navigator.pop(context); // Close drawer
                  _showEditProjectModal(context, project);
                } else if (value == 'delete') {
                  // Confirm and delete project
                  Navigator.pop(context); // Close drawer
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
                      Icon(Icons.delete, size: 18, color: AppColors.lightError),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.lightError)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.go('${Routes.tasks}?projectId=${project.id}');
      },
    );
  }

  // Method to show edit project modal
  void _showEditProjectModal(BuildContext context, ProjectEntity project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProjectFormWidget(
          project: project, // Pass existing project for editing
          onComplete: () {
            Navigator.pop(context);
            setState(() {
              _projectsRefreshCounter++;
            });
          },
        );
      },
    );
  }

  // Method to confirm and delete project
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
            style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
            onPressed: () async {
              Navigator.pop(context);
              // Delete the project
              await GetIt.I<IProjectRepository>().deleteProject(project.id);
              // Refresh the list
              if (mounted) {
                setState(() {
                  _projectsRefreshCounter++;
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // This builds the regular timer controls
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

  // Compact timer controls for focus mode
  Widget _buildCompactTimerControls(BuildContext context, TimerState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    if (state.status == TimerUIStatus.initial) {
      return IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => context.read<TimerBloc>().add(const TimerStarted()),
        iconSize: 36,
        color: primaryColor,
      );
    }

    if (state.status == TimerUIStatus.running) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => context.read<TimerBloc>().add(const TimerPaused()),
            iconSize: 28,
            color: secondaryColor,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
            iconSize: 28,
            color: Colors.red,
          ),
        ],
      );
    }

    if (state.status == TimerUIStatus.paused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () =>
                context.read<TimerBloc>().add(const TimerResumed()),
            iconSize: 28,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TimerBloc>().add(const TimerReset()),
            iconSize: 28,
            color: Colors.red,
          ),
        ],
      );
    }

    if (state.status == TimerUIStatus.breakRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => context.read<TimerBloc>().add(const TimerPaused()),
            iconSize: 28,
            color: secondaryColor,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () =>
                context.read<TimerBloc>().add(const TimerBreakSkipped()),
            iconSize: 28,
            color: Colors.orange,
          ),
        ],
      );
    }

    // For break ready, completed, or other states
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => state.timerMode == TimerMode.focus
              ? context.read<TimerBloc>().add(const TimerStarted())
              : context.read<TimerBloc>().add(const TimerBreakStarted()),
          iconSize: 28,
          color: state.timerMode == TimerMode.focus
              ? primaryColor
              : secondaryColor,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: () => state.timerMode == TimerMode.focus
              ? context.read<TimerBloc>().add(const TimerBreakStarted())
              : context.read<TimerBloc>().add(const TimerBreakSkipped()),
          iconSize: 28,
          color: Colors.orange,
        ),
      ],
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

  void _showCreateProjectModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProjectFormWidget(
          onComplete: () {
            // Close the sheet
            Navigator.pop(context);

            // Increment the refresh counter to rebuild the projects list
            setState(() {
              _projectsRefreshCounter++;
            });
          },
        );
      },
    );
  }
}
