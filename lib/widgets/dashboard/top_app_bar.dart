import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/dashboard_ui_state.dart';
import '../../screens/profile_setup_screen.dart';
import '../../screens/leaderboard_screen.dart';
import '../../screens/stats_dashboard_screen.dart';
import '../../screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardTopAppBar extends StatelessWidget {
  final bool isNarrow;
  final bool isRightSidebarExpanded;
  final DashboardUiState uiState;
  final VoidCallback onToggleRightSidebar;

  const DashboardTopAppBar({
    super.key,
    required this.isNarrow,
    required this.isRightSidebarExpanded,
    required this.uiState,
    required this.onToggleRightSidebar,
  });

  String get _userEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? 'Studier';

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171A1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
               color: AppColors.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Signed in as $_userEmail\n\nAre you sure you want to sign out?',
          style: const TextStyle(
               color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _signOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle( fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: AppColors.primary, size: 22),
      padding: const EdgeInsets.all(6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Brand
          const Text(
            'StudySync',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 16),

          // Room pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF171A1E),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: uiState.isLoading ? AppColors.outline : AppColors.greenActive,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  uiState.isLoading 
                      ? 'StudySync Global • Loading...' 
                      : 'StudySync Global • ${uiState.data?.globalCount ?? 0} Active Studiers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Nav links
          _navLink('Profile'),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, _, _) => const LeaderboardScreen(),
                transitionsBuilder: (_, anim, _, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
            child: const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, _, _) => const StatsDashboardScreen(),
                transitionsBuilder: (_, anim, _, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
            child: const Text(
              'My Stats',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 24),
          _navLink('Settings'),
          const SizedBox(width: 20),

          // Global Chat button
          Tooltip(
            message: 'Global Chat',
            child: InkWell(
              onTap: onToggleRightSidebar,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: isRightSidebarExpanded || isNarrow ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Icon buttons
          _iconBtn(Icons.group_outlined),
          const SizedBox(width: 4),
          _iconBtn(Icons.notifications_outlined),
          const SizedBox(width: 12),

          // Avatar — tap for account menu
          PopupMenuButton<String>(
            tooltip: 'Account',
            offset: const Offset(0, 42),
            color: const Color(0xFF1C2025),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit_profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileSetupScreen(isEditing: true),
                  ),
                );
              } else if (value == 'sign_out') {
                _showSignOutDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit_profile',
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 16),
                    SizedBox(width: 10),
                    Text('Edit Profile',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface,
                        )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded,
                        color: AppColors.logoutRed, size: 16),
                    SizedBox(width: 10),
                    Text('Sign Out',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.logoutRed,
                        )),
                  ],
                ),
              ),
            ],
            child: Tooltip(
              message: _userEmail,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceHighest,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
