import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/dashboard_ui_state.dart';
import '../../../services/chat_service.dart';
import '../../sidebar_chat.dart';
import 'narrow_right_rail.dart';
import 'trending_rooms.dart';
import 'leaderboard_section.dart';

class DashboardRightPanel extends StatelessWidget {
  final bool isMobile;
  final bool isExpanded;
  final DashboardUiState uiState;
  final ChatService chatService;
  final Future<void> Function() onRefresh;
  final VoidCallback onExpand;

  const DashboardRightPanel({
    super.key,
    required this.isMobile,
    required this.isExpanded,
    required this.uiState,
    required this.chatService,
    required this.onRefresh,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded && !isMobile) {
      return NarrowRightRail(onExpand: onExpand);
    }

    return Container(
      width: isMobile ? 320 : 288,
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        border: Border(left: BorderSide(color: Color(0x26A7ABB3), width: 1)),
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceHighest,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trending Rooms header
                    const Text(
                      'DISCOVER',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Trending Rooms',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TrendingRoomsSection(uiState: uiState, onRetry: onRefresh),

                    const SizedBox(height: 28),

                    // Leaderboard section
                    Row(
                      children: const [
                        Icon(
                          Icons.leaderboard_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LEADERBOARD (ALL TIME)',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LeaderboardSection(uiState: uiState, onRetry: onRefresh),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: SidebarChat(chatService: chatService, isGlobal: true),
            ),
          ],
        ),
      ),
    );
  }
}
