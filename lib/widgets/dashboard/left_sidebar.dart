import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/room_sheet.dart';

class DashboardLeftSidebar extends StatelessWidget {
  final bool isNarrow;

  const DashboardLeftSidebar({
    super.key,
    required this.isNarrow,
  });

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    bool active = false,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF171A1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          onTap: disabled ? null : () {},
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF171A1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.meeting_room_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Controls',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'DEEP WORK PHASE',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Nav items
          _sidebarItem(
            icon: Icons.play_circle_outline_rounded,
            label: 'Start Session',
            active: true,
          ),
          _sidebarItem(
            icon: Icons.timer_outlined,
            label: 'Timer',
            disabled: true,
          ),
          _sidebarItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Check-in',
            disabled: true,
          ),
          _sidebarItem(
            icon: Icons.info_outline_rounded,
            label: 'Session Info',
            disabled: true,
          ),
          _sidebarItem(
            icon: Icons.checklist_rounded,
            label: 'To-Do',
            disabled: false,
          ),

          const Spacer(),

          // Join Table button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => RoomSheet.show(context),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Join Table'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
