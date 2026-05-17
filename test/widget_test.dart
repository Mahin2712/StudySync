import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  testWidgets('StudySync app smoke test', (WidgetTester tester) async {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.currentSession).thenReturn(null);
    when(
      () => mockAuth.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());

    // Basic smoke test — just ensures the app builds without crashing
    await tester.pumpWidget(StudySyncApp(supabaseClient: mockClient));
  });
}
