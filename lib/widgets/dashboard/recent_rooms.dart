import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/room_sheet.dart';
import '../../models/dashboard_ui_state.dart';

class DashboardRecentRooms extends StatelessWidget {
  final DashboardUiState uiState;

  const DashboardRecentRooms({super.key, required this.uiState});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Recent Rooms',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: uiState.isLoading && uiState.data == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : uiState.error != null && uiState.data == null
                ? Center(
                    child: Text(
                      uiState.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  )
                : (uiState.data?.recentRooms ?? []).isEmpty
                ? Center(
                    child: Text(
                      'You haven\'t joined any rooms yet.',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: uiState.data!.recentRooms.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final r = uiState.data!.recentRooms[index];
                      return InkWell(
                        onTap: () => RoomSheet.show(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Rejoin',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
