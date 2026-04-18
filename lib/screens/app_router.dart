import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';

/// Async routing widget that evaluates auth state and profile completeness.
///
/// This is the single post-auth routing funnel. All entry points (cold start,
/// login, sign-up) must navigate to [AppRouter] so the profile-completion gate
/// is always enforced — never bypass this by pushing [HomeScreen] directly.
class AppRouter extends StatefulWidget {
  final SupabaseClient? supabaseClient;

  const AppRouter({super.key, this.supabaseClient});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget stale session cleanup.
    // Fallback for Supabase free-tier (no pg_cron).
    // Marks sessions inactive where last_activity_at < now - 25 min.
    final client = widget.supabaseClient ?? Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      SessionService.cleanUpStaleSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.supabaseClient ?? Supabase.instance.client;
    final session = client.auth.currentSession;

    // Not logged in → go to login
    if (session == null) return const LoginScreen();

    // Logged in → check if profile is complete before allowing home
    return FutureBuilder<bool>(
      future: ProfileService.isProfileComplete(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0C0E11),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFADCBDB)),
            ),
          );
        }
        final isComplete = snap.data ?? false;
        if (!isComplete) return const ProfileSetupScreen();
        return const HomeScreen();
      },
    );
  }
}
