import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  });

  testWidgets('StudySync app smoke test', (WidgetTester tester) async {
    // Basic smoke test — just ensures the app builds without crashing
    await tester.pumpWidget(const StudySyncApp());
  });
}
