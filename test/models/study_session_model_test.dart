import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/study_session_model.dart';

void main() {
  group('StudySessionModel.formatDuration', () {
    test('formats zero duration correctly', () {
      expect(StudySessionModel.formatDuration(Duration.zero), '00:00:00');
    });

    test('formats seconds-only duration correctly', () {
      expect(
        StudySessionModel.formatDuration(const Duration(seconds: 45)),
        '00:00:45',
      );
    });

    test('formats minutes and seconds correctly', () {
      expect(
        StudySessionModel.formatDuration(const Duration(minutes: 5, seconds: 30)),
        '00:05:30',
      );
    });

    test('formats hours, minutes and seconds correctly', () {
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '01:02:03',
      );
    });

    test('formats duration over 24 hours correctly', () {
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 25, minutes: 30, seconds: 15),
        ),
        '25:30:15',
      );
    });

    test('formats very large duration correctly', () {
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 100, minutes: 0, seconds: 0),
        ),
        '100:00:00',
      );
    });

    test('handles single digit components with padding', () {
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 9, minutes: 9, seconds: 9),
        ),
        '09:09:09',
      );
    });
  });
}
