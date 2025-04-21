// lib/features/timer/presentation/widgets/timer_display.dart

import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final double progress;
  final String? statusText;
  final Color? progressColor;

  // New parameters for different display modes
  final bool large;
  final bool compact;

  const TimerDisplay({
    Key? key,
    required this.timeRemaining,
    required this.progress,
    this.statusText,
    this.progressColor,
    this.large = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format time as mm:ss
    final minutes = (timeRemaining / 60).floor();
    final seconds = timeRemaining % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Get screen size to determine if we're on a larger device
    final screenWidth = MediaQuery.of(context).size.width;

    // Define sizes based on display mode and device type
    double timerSize;
    double strokeWidth;
    double fontSizeFactor;

    if (compact) {
      // Compact mode for focus view
      timerSize = 150.0;
      strokeWidth = 6.0;
      fontSizeFactor = 0.7;
    } else if (large) {
      // Large mode for fullscreen
      timerSize = screenWidth > 600 ? 400.0 : screenWidth * 0.8;
      strokeWidth = screenWidth > 600 ? 12.0 : 10.0;
      fontSizeFactor = screenWidth > 600 ? 1.4 : 1.2;
    } else {
      // Regular mode
      timerSize = screenWidth > 600 ? 320.0 : 260.0;
      strokeWidth = screenWidth > 600 ? 10.0 : 8.0;
      fontSizeFactor = screenWidth > 600 ? 1.2 : 1.0;
    }

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusText != null && !compact)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 16,
                vertical: compact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: progressColor?.withOpacity(0.2) ??
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                statusText!,
                style: compact
                    ? TextStyle(
                        fontSize: 12,
                        color: progressColor ??
                            Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )
                    : TextStyle(
                        fontSize: 14,
                        color: progressColor ??
                            Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: timerSize,
            height: timerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: timerSize,
                  height: timerSize,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween<double>(
                      begin: 0,
                      end: progress,
                    ),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: strokeWidth,
                      backgroundColor: (progressColor ??
                              Theme.of(context).colorScheme.primary)
                          .withOpacity(0.2),
                      color: progressColor ??
                          Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (compact && statusText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          statusText!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: progressColor ??
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        formattedTime,
                        key: ValueKey(formattedTime),
                        style: compact
                            ? TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              )
                            : TextStyle(
                                fontSize: large ? 72 : 60,
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
