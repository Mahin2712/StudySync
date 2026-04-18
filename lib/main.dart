import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/profile_service.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(StudySyncApp(supabaseClient: Supabase.instance.client));
}

class StudySyncApp extends StatelessWidget {
  final SupabaseClient? supabaseClient;

  const StudySyncApp({super.key, this.supabaseClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0C0E11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFADCBDB),
          surface: Color(0xFF111417),
        ),
      ),
      home: _AppRouter(supabaseClient: supabaseClient ?? Supabase.instance.client),
    );
  }
}

/// Async routing widget that checks auth state and profile completeness.
class _AppRouter extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const _AppRouter({required this.supabaseClient});

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget stale session cleanup.
    // Fallback for Supabase free-tier (no pg_cron).
    // Marks sessions inactive where last_activity_at < now - 25 min.
    final user = widget.supabaseClient.auth.currentUser;
    if (user != null) {
      SessionService.cleanUpStaleSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.supabaseClient.auth.currentSession;

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
