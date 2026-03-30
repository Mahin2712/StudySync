import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/main.dart';

void main() {
  testWidgets('StudySync app smoke test', (WidgetTester tester) async {
    // Basic smoke test — just ensures the app builds without crashing
    await tester.pumpWidget(const StudySyncApp());
  });
}
