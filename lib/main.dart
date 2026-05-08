import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_router.dart';
import 'services/device_identity_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark as per design system

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
  }
}

final themeProvider = ThemeProvider();

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
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'StudySync',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Inter',
            fontFamilyFallback: const ['PurnoBCC'],
            textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Inter',
              fontFamilyFallback: ['PurnoBCC'],
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF395664),
              surface: Color(0xFFFFFFFF),
              outline: Color(0xFFE2E8F0),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
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
              outline: Color(0xFF44484F),
            ),
          ),
          home: AppRouter(supabaseClient: supabaseClient),
        );
      },
    );
  }
}
