import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class NarrowRightRail extends StatelessWidget {
  final VoidCallback onExpand;

  const NarrowRightRail({super.key, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF111417),
        border: Border(left: BorderSide(color: Color(0x26A7ABB3), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Tooltip(
            message: 'Active Peers',
            child: Icon(
              Icons.people_alt_outlined,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
          const Tooltip(
            message: 'Leaderboard',
            child: Icon(
              Icons.emoji_events_outlined,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Expand Sidebar',
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_double_arrow_left_rounded,
                color: AppColors.primary,
              ),
              onPressed: onExpand,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
