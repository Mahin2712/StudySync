import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Compact streak badge for the dashboard.
/// Shows 🔥 and the current streak count with a subtle glow effect.
class StreakBadge extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakBadge({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStreak > 0;
    final fireColor = isActive
        ? const Color(0xFFFF9800) // warm orange
        : AppColors.onSurfaceVariant;
    final glowAlpha = isActive ? 0.15 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fireColor.withValues(alpha: 0.25)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: fireColor.withValues(alpha: glowAlpha),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fire icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fireColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                isActive ? '🔥' : '❄️',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Streak text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isActive ? '$currentStreak day streak' : 'No streak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? fireColor : AppColors.onSurfaceVariant,
                ),
              ),
              if (longestStreak > 0)
                Text(
                  'Best: $longestStreak days',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
