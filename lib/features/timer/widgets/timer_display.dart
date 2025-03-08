import 'package:flutter/material.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';

class TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final double progress;
  final String? statusText;
  final Color? progressColor;

  const TimerDisplay({
    Key? key,
    required this.timeRemaining,
    required this.progress,
    this.statusText,
    this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format time as mm:ss
    final minutes = (timeRemaining / 60).floor();
    final seconds = timeRemaining % 60;
    final formattedTime = 
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        if (statusText != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color: progressColor?.withOpacity(0.2) ?? 
                     Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              statusText!,
              style: AppTextStyles.labelMedium(context).copyWith(
                color: progressColor ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Timer container with progress indicator
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.width * 0.7,
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
              // Progress indicator
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: (progressColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
                  color: progressColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              
              // Timer text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: AppTextStyles.displayMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}