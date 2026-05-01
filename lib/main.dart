import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/app_router.dart';
import 'services/device_identity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await DeviceIdentityService.ensureInitialized();

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
        useMaterial3: true,
        brightness: Brightness.dark,
        // Use the bundled Inter font family
        fontFamily: 'Inter',
        fontFamilyFallback: const ['PurnoBCC'],
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Inter',
          fontFamilyFallback: ['PurnoBCC'],
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0E11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFADCBDB),
          surface: Color(0xFF111417),
        ),
      ),
      home: AppRouter(supabaseClient: supabaseClient),
    );
  }
}
