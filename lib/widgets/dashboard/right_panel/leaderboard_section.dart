import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/dashboard_ui_state.dart';

class LeaderboardSection extends StatelessWidget {
  final DashboardUiState uiState;
  final VoidCallback onRetry;

  const LeaderboardSection({
    super.key,
    required this.uiState,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (uiState.isLoading && uiState.data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (uiState.error != null && uiState.data == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              uiState.error!,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final lb = uiState.data?.leaderboard ?? [];
    if (lb.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.outlineVariant,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              'No active leaderboard yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Top Studiers',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: lb.asMap().entries.map((entry) {
          final idx = entry.key;
          final user = entry.value;
          Color rankColor = AppColors.onSurfaceVariant;
          if (idx == 0) rankColor = const Color(0xFFFFD700); // Gold
          if (idx == 1) rankColor = const Color(0xFFC0C0C0); // Silver
          if (idx == 2) rankColor = const Color(0xFFCD7F32); // Bronze

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(
              '#${idx + 1}',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            title: Text(
              user.username,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
            ),
            trailing: Text(
              user.formattedHours,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
