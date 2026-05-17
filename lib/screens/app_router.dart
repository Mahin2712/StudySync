import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';

/// Async routing widget that evaluates auth state and profile completeness.
///
/// Fix #2: Now reactive — subscribes to [onAuthStateChange] so sign-outs and
/// sign-ins propagate automatically without relying on manual Navigator pushes.
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
  late final SupabaseClient _client;

  // Fix #2: track the live session so build() stays reactive.
  Session? _session;
  StreamSubscription<AuthState>? _authSub;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinksSub;

  @override
  void initState() {
    super.initState();
    _client = widget.supabaseClient ?? Supabase.instance.client;

    // Seed with the current snapshot so the first frame renders correctly.
    _session = _client.auth.currentSession;

    // Fire-and-forget stale session cleanup (fallback for Supabase free-tier).
    if (_session != null) {
      SessionService.cleanUpStaleSessions();
    }

    // Fix #2: Subscribe to auth state changes and rebuild whenever the
    // session is created, refreshed, or destroyed.
    _authSub = _client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
      });

      // Re-run stale session cleanup whenever a user signs in.
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        SessionService.cleanUpStaleSessions();
      }
    });

    // Handle deep links for platforms that don't auto-intercept (e.g. Windows)
    _appLinks = AppLinks();
    _appLinksSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'studysync') {
        _client.auth.getSessionFromUrl(uri);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _appLinksSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fix #2: Use the live _session field instead of a one-shot snapshot.
    if (_session == null) return const LoginScreen();

    // Logged in → check if profile is complete before allowing home.
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
