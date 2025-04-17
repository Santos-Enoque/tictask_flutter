
import 'package:flutter/material.dart';
import 'package:tictask/features/timer/presentation/bloc/timer_bloc.dart';

class TimerControls extends StatelessWidget {
  final TimerUIStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onStartBreak;
  final VoidCallback onSkipBreak;
  final bool isFocusMode;

  const TimerControls({
    Key? key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onStartBreak,
    required this.onSkipBreak,
    required this.isFocusMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildControlButtons(context),
      ),
    );
  }

  List<Widget> _buildControlButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (status) {
      case TimerUIStatus.initial:
        return [
          _buildButton(
            context: context,
            onPressed: onStart,
            icon: Icons.play_arrow,
            label: 'Start',
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            iconColor: colorScheme.onPrimary,
          ),
        ];

      case TimerUIStatus.running:
        return [
          _buildButton(
            context: context,
            onPressed: onPause,
            icon: Icons.pause,
            label: 'Pause',
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            iconColor: colorScheme.onPrimary,
          ),
          const SizedBox(width: 16),
          _buildButton(
            context: context,
            onPressed: onReset,
            icon: Icons.refresh,
            label: 'Reset',
            backgroundColor: Colors.transparent,
            textColor: colorScheme.primary,
            iconColor: colorScheme.primary,
            borderColor: colorScheme.outline,
          ),
        ];

      case TimerUIStatus.paused:
        return [
          _buildButton(
            context: context,
            onPressed: onResume,
            icon: Icons.play_arrow,
            label: 'Resume',
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            iconColor: colorScheme.onPrimary,
          ),
          const SizedBox(width: 16),
          _buildButton(
            context: context,
            onPressed: onReset,
            icon: Icons.refresh,
            label: 'Reset',
            backgroundColor: Colors.transparent,
            textColor: colorScheme.primary,
            iconColor: colorScheme.primary,
            borderColor: colorScheme.outline,
          ),
        ];

      case TimerUIStatus.breakReady:
        return [
          _buildButton(
            context: context,
            onPressed: onStartBreak,
            icon: Icons.free_breakfast,
            label: 'Start Break',
            backgroundColor: colorScheme.secondary,
            textColor: colorScheme.onSecondary,
            iconColor: colorScheme.onSecondary,
          ),
          const SizedBox(width: 16),
          _buildButton(
            context: context,
            onPressed: onSkipBreak,
            icon: Icons.skip_next,
            label: 'Skip Break',
            backgroundColor: Colors.transparent,
            textColor: colorScheme.secondary,
            iconColor: colorScheme.secondary,
            borderColor: colorScheme.outline,
          ),
        ];

      case TimerUIStatus.breakRunning:
        return [
          _buildButton(
            context: context,
            onPressed: onPause,
            icon: Icons.pause,
            label: 'Pause',
            backgroundColor: colorScheme.secondary,
            textColor: colorScheme.onSecondary,
            iconColor: colorScheme.onSecondary,
          ),
          const SizedBox(width: 16),
          _buildButton(
            context: context,
            onPressed: onSkipBreak,
            icon: Icons.skip_next,
            label: 'Skip',
            backgroundColor: Colors.transparent,
            textColor: colorScheme.secondary,
            iconColor: colorScheme.secondary,
            borderColor: colorScheme.outline,
          ),
        ];

      default:
        return [
          _buildButton(
            context: context,
            onPressed: onStart,
            icon: Icons.play_arrow,
            label: 'Start',
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            iconColor: colorScheme.onPrimary,
          ),
        ];
    }
  }

  Widget _buildButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    // For focus mode, use a more compact button
    if (isFocusMode) {
      return IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: iconColor,
      ),
      label: Text(
        label,
        style: TextStyle(color: textColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
      ),
    );
  }
}
