import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/models.dart';
import 'package:tictask/features/timer/widgets/widgets.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TicTask Timer'),
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
                  TimerControls(
                    status: state.status,
                    isFocusMode: state.timerMode == TimerMode.focus,
                    onStart: () =>
                        context.read<TimerBloc>().add(const TimerStarted()),
                    onPause: () =>
                        context.read<TimerBloc>().add(const TimerPaused()),
                    onResume: () =>
                        context.read<TimerBloc>().add(const TimerResumed()),
                    onReset: () =>
                        context.read<TimerBloc>().add(const TimerReset()),
                    onStartBreak: () => context
                        .read<TimerBloc>()
                        .add(const TimerBreakStarted()),
                    onSkipBreak: () => context
                        .read<TimerBloc>()
                        .add(const TimerBreakSkipped()),
                  ),

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
                        Icons.access_time,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Optional: Add a bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            // Navigate to settings
            context.push(Routes.settings);
          }
          // Handle other navigation options as needed
        },
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
                style: AppTextStyles.labelMedium(context).copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            value,
            style: AppTextStyles.headlineSmall(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
