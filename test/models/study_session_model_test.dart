import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/study_session_model.dart';

void main() {
  group('StudySessionModel', () {
    final now = DateTime.now().toUtc();
    final startTime = now.subtract(const Duration(minutes: 30));
    final createdAt = now.subtract(const Duration(minutes: 35));

    final testJson = {
      'id': 'test-id',
      'user_id': 'test-user',
      'room_id': 'test-room',
      'subject': 'Mathematics',
      'start_time': startTime.toIso8601String(),
      'end_time': null,
      'is_active': true,
      'created_at': createdAt.toIso8601String(),
      'last_activity_at': null,
      'missed_checkins': 0,
    };

    test('fromJson creates a valid model', () {
      final model = StudySessionModel.fromJson(testJson);

      expect(model.id, 'test-id');
      expect(model.userId, 'test-user');
      expect(model.roomId, 'test-room');
      expect(model.subject, 'Mathematics');
      expect(model.startTime, startTime);
      expect(model.endTime, isNull);
      expect(model.isActive, true);
      expect(model.createdAt, createdAt);
      expect(model.lastActivityAt, isNull);
      expect(model.missedCheckins, 0);
    });

    group('Getters', () {
      test('elapsed calculates difference from startTime', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(hours: 1)),
          isActive: true,
          createdAt: now,
        );

        // Allow some slack for execution time
        expect(model.elapsed.inHours, 1);
      });

      test('timeSinceActivity uses startTime if lastActivityAt is null', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 10)),
          isActive: true,
          createdAt: now,
          lastActivityAt: null,
        );

        expect(model.timeSinceActivity.inMinutes, 10);
      });

      test('timeSinceActivity uses lastActivityAt if present', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(hours: 1)),
          isActive: true,
          createdAt: now,
          lastActivityAt: now.subtract(const Duration(minutes: 5)),
        );

        expect(model.timeSinceActivity.inMinutes, 5);
      });

      test('isCheckinDue returns true when interval elapsed', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 25)),
          isActive: true,
          createdAt: now,
        );

        expect(model.isCheckinDue, true);
      });

      test('isCheckinDue returns false before interval', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 15)),
          isActive: true,
          createdAt: now,
        );

        expect(model.isCheckinDue, false);
      });

      test('isAutoStopDue returns true after interval + grace', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 22)),
          isActive: true,
          createdAt: now,
        );

        // 20 min interval + 60s grace = 21 mins. 22 mins is past.
        expect(model.isAutoStopDue, true);
      });

      test('nextCheckinAt returns null if lastActivityAt is null', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now,
          isActive: true,
          createdAt: now,
        );

        expect(model.nextCheckinAt, isNull);
      });

      test('nextCheckinAt calculates correctly from lastActivityAt', () {
        final lastActivity = now.subtract(const Duration(minutes: 5));
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 30)),
          isActive: true,
          createdAt: now,
          lastActivityAt: lastActivity,
        );

        expect(model.nextCheckinAt, lastActivity.add(StudySessionModel.checkinInterval));
      });

      test('checkinStatus handles null lastActivityAt', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 30)),
          isActive: true,
          createdAt: now,
          lastActivityAt: null,
        );

        expect(model.checkinStatus, CheckinStatus.active);
      });

      test('checkinStatus transitions to warning after interval', () {
        final model = StudySessionModel(
          id: '1',
          userId: 'u1',
          roomId: 'r1',
          startTime: now.subtract(const Duration(minutes: 30)),
          isActive: true,
          createdAt: now,
          lastActivityAt: now.subtract(const Duration(minutes: 25)),
        );

        expect(model.checkinStatus, CheckinStatus.warning);
      });
    });

    group('formatDuration', () {
      test('formats zero duration', () {
        expect(StudySessionModel.formatDuration(Duration.zero), '00:00:00');
      });

      test('formats sub-hour duration', () {
        const d = Duration(minutes: 45, seconds: 30);
        expect(StudySessionModel.formatDuration(d), '00:45:30');
      });

      test('formats multi-hour duration', () {
        const d = Duration(hours: 2, minutes: 5, seconds: 9);
        expect(StudySessionModel.formatDuration(d), '02:05:09');
      });

      test('formats duration > 24h', () {
        const d = Duration(hours: 25, minutes: 0, seconds: 0);
        expect(StudySessionModel.formatDuration(d), '25:00:00');
      });
    });
  });
}
