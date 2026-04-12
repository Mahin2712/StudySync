import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/study_session_model.dart';

void main() {
  group('StudySessionModel', () {
    final startTime = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final createdAt = startTime.subtract(const Duration(minutes: 1));

    final baseJson = {
      'id': 'session-123',
      'user_id': 'user-456',
      'room_id': 'room-789',
      'subject': 'Mathematics',
      'start_time': startTime.toIso8601String(),
      'is_active': true,
      'created_at': createdAt.toIso8601String(),
      'missed_checkins': 0,
    };

    test('fromJson handles all fields correctly', () {
      final lastActivityAt = startTime.add(const Duration(minutes: 30));
      final endTime = startTime.add(const Duration(hours: 2));
      final json = Map<String, dynamic>.from(baseJson)
        ..['last_activity_at'] = lastActivityAt.toIso8601String()
        ..['end_time'] = endTime.toIso8601String()
        ..['missed_checkins'] = 2;

      final model = StudySessionModel.fromJson(json);

      expect(model.id, 'session-123');
      expect(model.userId, 'user-456');
      expect(model.roomId, 'room-789');
      expect(model.subject, 'Mathematics');
      // DateTime.parse might lose some precision or handle timezones differently if not careful,
      // but here we use toUtc() and toIso8601String()
      expect(model.startTime.isAtSameMomentAs(startTime), isTrue);
      expect(model.endTime!.isAtSameMomentAs(endTime), isTrue);
      expect(model.isActive, true);
      expect(model.createdAt.isAtSameMomentAs(createdAt), isTrue);
      expect(model.lastActivityAt!.isAtSameMomentAs(lastActivityAt), isTrue);
      expect(model.missedCheckins, 2);
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..remove('subject')
        ..remove('is_active'); // should default to false

      final model = StudySessionModel.fromJson(json);

      expect(model.subject, isNull);
      expect(model.isActive, false);
      expect(model.lastActivityAt, isNull);
      expect(model.endTime, isNull);
    });

    group('formatDuration', () {
      test('formats zero duration', () {
        expect(StudySessionModel.formatDuration(Duration.zero), '00:00:00');
      });

      test('formats duration under one hour', () {
        expect(
          StudySessionModel.formatDuration(const Duration(minutes: 45, seconds: 30)),
          '00:45:30',
        );
      });

      test('formats duration over one hour', () {
        expect(
          StudySessionModel.formatDuration(const Duration(hours: 2, minutes: 5, seconds: 9)),
          '02:05:09',
        );
      });

      test('formats duration over 24 hours', () {
        expect(
          StudySessionModel.formatDuration(const Duration(hours: 25, minutes: 0, seconds: 0)),
          '25:00:00',
        );
      });
    });

    test('elapsed returns correct duration', () {
      final model = StudySessionModel(
        id: '1',
        userId: '1',
        roomId: '1',
        startTime: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
        isActive: true,
        createdAt: DateTime.now().toUtc(),
      );

      final elapsed = model.elapsed;
      // Should be around 10 minutes
      expect(elapsed.inMinutes, 10);
      expect(elapsed.inSeconds, greaterThanOrEqualTo(600));
    });

    group('timeSinceActivity', () {
      test('uses startTime if lastActivityAt is null', () {
        final start = DateTime.now().toUtc().subtract(const Duration(minutes: 15));
        final model = StudySessionModel(
          id: '1',
          userId: '1',
          roomId: '1',
          startTime: start,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          lastActivityAt: null,
        );

        expect(model.timeSinceActivity.inMinutes, 15);
      });

      test('uses lastActivityAt if present', () {
        final start = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
        final lastActive = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
        final model = StudySessionModel(
          id: '1',
          userId: '1',
          roomId: '1',
          startTime: start,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          lastActivityAt: lastActive,
        );

        expect(model.timeSinceActivity.inMinutes, 5);
      });
    });

    group('Check-in logic', () {
      test('isCheckinDue works correctly', () {
        final now = DateTime.now().toUtc();

        final modelNotDue = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true, createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 19, seconds: 59)),
        );
        expect(modelNotDue.isCheckinDue, isFalse);

        final modelDue = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true, createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 20)),
        );
        expect(modelDue.isCheckinDue, isTrue);
      });

      test('isAutoStopDue works correctly', () {
        final now = DateTime.now().toUtc();

        final modelNotDue = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true, createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 20, seconds: 59)),
        );
        expect(modelNotDue.isAutoStopDue, isFalse);

        final modelDue = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true, createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 21, seconds: 1)),
        );
        expect(modelDue.isAutoStopDue, isTrue);
      });

      test('nextCheckinAt returns null if lastActivityAt is null', () {
         final model = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true,
          createdAt: DateTime.now().toUtc(),
          startTime: DateTime.now().toUtc(),
          lastActivityAt: null,
        );
        expect(model.nextCheckinAt, isNull);
      });

      test('nextCheckinAt returns lastActivityAt + checkinInterval', () {
        final lastActive = DateTime.now().toUtc();
        final model = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true,
          createdAt: DateTime.now().toUtc(),
          startTime: DateTime.now().toUtc(),
          lastActivityAt: lastActive,
        );
        expect(model.nextCheckinAt!.isAtSameMomentAs(lastActive.add(StudySessionModel.checkinInterval)), isTrue);
      });

      test('checkinStatus returns active if lastActivityAt is null', () {
        final model = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true,
          createdAt: DateTime.now().toUtc(),
          startTime: DateTime.now().toUtc(),
          lastActivityAt: null,
        );
        expect(model.checkinStatus, CheckinStatus.active);
      });

      test('checkinStatus returns warning when check-in is due', () {
        final now = DateTime.now().toUtc();
        final model = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true,
          createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 20)),
        );
        expect(model.checkinStatus, CheckinStatus.warning);
      });

      test('checkinStatus returns active when check-in is not yet due', () {
        final now = DateTime.now().toUtc();
        final model = StudySessionModel(
          id: '1', userId: '1', roomId: '1', isActive: true,
          createdAt: now,
          startTime: now,
          lastActivityAt: now.subtract(const Duration(minutes: 19)),
        );
        expect(model.checkinStatus, CheckinStatus.active);
      });
    });
  });
}
