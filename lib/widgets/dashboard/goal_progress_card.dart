import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/goal_service.dart';

/// Circular progress indicator showing today's study time vs. daily goal.
/// Used on the dashboard right panel.
class GoalProgressCard extends StatelessWidget {
  final GoalProgress progress;
  final VoidCallback? onSetGoal;

  const GoalProgressCard({
    super.key,
    required this.progress,
    this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = progress.goalMinutes > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: hasGoal ? _buildProgressState() : _buildNoGoalState(),
    );
  }

  Widget _buildProgressState() {
    final fraction = (progress.studiedMinutes / progress.goalMinutes)
        .clamp(0.0, 1.0);
    final percentage = (fraction * 100).round();
    final isComplete = progress.isGoalMet;
    final ringColor = isComplete
        ? AppColors.greenActive
        : AppColors.primary;

    return Column(
      children: [
        // Ring
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ringColor.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isComplete)
                    const Text('✅', style: TextStyle(fontSize: 20))
                  else
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ringColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Label
        Text(
          isComplete ? 'Goal Complete! 🎉' : 'Daily Goal',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isComplete ? AppColors.greenActive : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.studiedMinutes.round()} / ${progress.goalMinutes} min',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNoGoalState() {
    return Column(
      children: [
        const Icon(
          Icons.flag_outlined,
          color: AppColors.onSurfaceVariant,
          size: 28,
        ),
        const SizedBox(height: 8),
        const Text(
          'Set your daily goal',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track your daily study progress',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        if (onSetGoal != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: onSetGoal,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Set Goal →'),
          ),
        ],
      ],
    );
  }
}
