import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../screens/room_sheet.dart';
import '../../../models/dashboard_ui_state.dart';

class TrendingRoomsSection extends StatelessWidget {
  final DashboardUiState uiState;
  final VoidCallback onRetry;

  const TrendingRoomsSection({
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

    final rooms = uiState.data?.trendingRooms ?? [];
    if (rooms.isEmpty) {
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
              Icons.meeting_room_outlined,
              color: AppColors.outlineVariant,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              'No trending rooms yet.',
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
          'Top Rooms',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: rooms
            .map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.tag,
                  color: AppColors.primary,
                  size: 16,
                ),
                title: Text(
                  r.name,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppColors.onSurfaceVariant,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${r.memberCount}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () => RoomSheet.show(context),
              ),
            )
            .toList(),
      ),
    );
  }
}
