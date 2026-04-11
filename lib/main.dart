import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uenpxgcngqzggxmqifpw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVlbnB4Z2NuZ3F6Z2d4bXFpZnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3OTE2MDYsImV4cCI6MjA5MDM2NzYwNn0.bCat6zf7OoRLH_r598fPfDLxdUUS2i7CnNpG7uNLeNM',
  );

  runApp(const StudySyncApp());
}

class StudySyncApp extends StatelessWidget {
  const StudySyncApp({super.key});

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
      home: const _AppRouter(),
    );
  }
}

/// Async routing widget that checks auth state and profile completeness.
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

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
