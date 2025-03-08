import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/widgets/widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TimerBloc>().add(const TimerInitialized());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TicTask Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              context.push(Routes.settings);
            },
          ),
        ],
      ),
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

          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer display
                  TimerDisplay(
                    timeRemaining: state.timeRemaining,
                    progress: state.progress,
                    statusText: statusText,
                    progressColor: statusColor,
                  ),

                  // Gap
                  const SizedBox(height: AppDimensions.xxl),

                  // Timer controls
                  _buildCupertinoTimerControls(context, state),

                  // Gap
                  const SizedBox(height: AppDimensions.xxl),

                  // Stats
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

  Widget _buildCupertinoTimerControls(BuildContext context, TimerState state) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    if (state.status == TimerStatus.idle) {
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

    if (state.status == TimerStatus.running) {
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

    if (state.status == TimerStatus.paused) {
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

    if (state.status == TimerStatus.break_) {
      // Break time logic
      if (state.timerMode == TimerMode.focus) {
        // Focus ended, show break options
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
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
          const SizedBox(height: AppDimensions.xs),
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
