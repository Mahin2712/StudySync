import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock/clock.dart';
import 'package:studysync/models/study_session_model.dart';

void main() {
  group('StudySessionModel.fromJson', () {
    test('should correctly parse a complete JSON object', () {
      final json = {
        'id': 'session-123',
        'user_id': 'user-456',
        'room_id': 'room-789',
        'device_id': 'device-abc',
        'device_type': 'android',
        'subject': 'Mathematics',
        'start_time': '2023-10-27T10:00:00Z',
        'end_time': '2023-10-27T12:00:00Z',
        'is_active': true,
        'created_at': '2023-10-27T09:55:00Z',
        'last_activity_at': '2023-10-27T11:30:00Z',
        'missed_checkins': 2,
      };

      final model = StudySessionModel.fromJson(json);

      expect(model.id, 'session-123');
      expect(model.userId, 'user-456');
      expect(model.roomId, 'room-789');
      expect(model.deviceId, 'device-abc');
      expect(model.deviceType, 'android');
      expect(model.subject, 'Mathematics');
      expect(model.startTime, DateTime.parse('2023-10-27T10:00:00Z').toUtc());
      expect(model.endTime, DateTime.parse('2023-10-27T12:00:00Z').toUtc());
      expect(model.isActive, isTrue);
      expect(model.createdAt, DateTime.parse('2023-10-27T09:55:00Z').toUtc());
      expect(
        model.lastActivityAt,
        DateTime.parse('2023-10-27T11:30:00Z').toUtc(),
      );
      expect(model.missedCheckins, 2);
    });

    test('should handle missing optional fields and provide defaults', () {
      final json = {
        'id': 'session-123',
        'user_id': 'user-456',
        'room_id': 'room-789',
        'start_time': '2023-10-27T10:00:00Z',
        'created_at': '2023-10-27T09:55:00Z',
      };

      final model = StudySessionModel.fromJson(json);

      expect(model.id, 'session-123');
      expect(model.deviceId, isNull);
      expect(model.deviceType, isNull);
      expect(model.subject, isNull);
      expect(model.endTime, isNull);
      expect(model.lastActivityAt, isNull);
      expect(model.isActive, isFalse);
      expect(model.missedCheckins, 0);
    });

    test('should handle explicit nulls for optional fields', () {
      final json = {
        'id': 'session-123',
        'user_id': 'user-456',
        'room_id': 'room-789',
        'device_id': null,
        'device_type': null,
        'subject': null,
        'start_time': '2023-10-27T10:00:00Z',
        'end_time': null,
        'is_active': null,
        'created_at': '2023-10-27T09:55:00Z',
        'last_activity_at': null,
        'missed_checkins': null,
      };

      final model = StudySessionModel.fromJson(json);

      expect(model.id, 'session-123');
      expect(model.deviceId, isNull);
      expect(model.deviceType, isNull);
      expect(model.subject, isNull);
      expect(model.endTime, isNull);
      expect(model.lastActivityAt, isNull);
      expect(model.isActive, isFalse);
      expect(model.missedCheckins, 0);
    });
  });

  group('StudySessionModel computed properties', () {
    final fixedTime = DateTime.parse('2023-10-27T12:00:00Z').toUtc();
    final startTime = DateTime.parse('2023-10-27T10:00:00Z').toUtc();
    final createdAt = DateTime.parse('2023-10-27T09:55:00Z').toUtc();

    test('elapsed calculation', () {
      withClock(Clock.fixed(fixedTime), () {
        final model = StudySessionModel(
          id: '1',
          userId: '1',
          roomId: '1',
          startTime: startTime,
          isActive: true,
          createdAt: createdAt,
        );

        expect(model.elapsed, const Duration(hours: 2));
      });
    });

    group('timeSinceActivity', () {
      test('should use lastActivityAt if present', () {
        final lastActivityAt = DateTime.parse('2023-10-27T11:30:00Z').toUtc();
        withClock(Clock.fixed(fixedTime), () {
          final model = StudySessionModel(
            id: '1',
            userId: '1',
            roomId: '1',
            startTime: startTime,
            isActive: true,
            createdAt: createdAt,
            lastActivityAt: lastActivityAt,
          );

          expect(model.timeSinceActivity, const Duration(minutes: 30));
        });
      });

      test('should fallback to startTime if lastActivityAt is null', () {
        withClock(Clock.fixed(fixedTime), () {
          final model = StudySessionModel(
            id: '1',
            userId: '1',
            roomId: '1',
            startTime: startTime,
            isActive: true,
            createdAt: createdAt,
            lastActivityAt: null,
          );

          expect(model.timeSinceActivity, const Duration(hours: 2));
        });
      });
    });

    group('Check-in and Auto-stop logic', () {
      test(
        'isCheckinDue should be true when timeSinceActivity >= checkinInterval',
        () {
          // checkinInterval is 20 minutes
          final lastActivityAt = fixedTime.subtract(
            const Duration(minutes: 20),
          );
          withClock(Clock.fixed(fixedTime), () {
            final model = StudySessionModel(
              id: '1',
              userId: '1',
              roomId: '1',
              startTime: startTime,
              isActive: true,
              createdAt: createdAt,
              lastActivityAt: lastActivityAt,
            );

            expect(model.isCheckinDue, isTrue);
            expect(model.checkinStatus, CheckinStatus.warning);
          });
        },
      );

      test(
        'isCheckinDue should be false when timeSinceActivity < checkinInterval',
        () {
          final lastActivityAt = fixedTime.subtract(
            const Duration(minutes: 19, seconds: 59),
          );
          withClock(Clock.fixed(fixedTime), () {
            final model = StudySessionModel(
              id: '1',
              userId: '1',
              roomId: '1',
              startTime: startTime,
              isActive: true,
              createdAt: createdAt,
              lastActivityAt: lastActivityAt,
            );

            expect(model.isCheckinDue, isFalse);
            expect(model.checkinStatus, CheckinStatus.active);
          });
        },
      );

      test(
        'isAutoStopDue should be true when timeSinceActivity >= checkinInterval + checkinGrace',
        () {
          // checkinGrace is 60 seconds
          final lastActivityAt = fixedTime.subtract(
            const Duration(minutes: 21),
          );
          withClock(Clock.fixed(fixedTime), () {
            final model = StudySessionModel(
              id: '1',
              userId: '1',
              roomId: '1',
              startTime: startTime,
              isActive: true,
              createdAt: createdAt,
              lastActivityAt: lastActivityAt,
            );

            expect(model.isAutoStopDue, isTrue);
          });
        },
      );

      test('nextCheckinAt should be lastActivityAt + checkinInterval', () {
        final lastActivityAt = DateTime.parse('2023-10-27T11:00:00Z').toUtc();
        final model = StudySessionModel(
          id: '1',
          userId: '1',
          roomId: '1',
          startTime: startTime,
          isActive: true,
          createdAt: createdAt,
          lastActivityAt: lastActivityAt,
        );

        expect(
          model.nextCheckinAt,
          DateTime.parse('2023-10-27T11:20:00Z').toUtc(),
        );
      });
    });
  });

  group('StudySessionModel.formatDuration', () {
    test('should format duration as HH:MM:SS', () {
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '01:02:03',
      );
      expect(
        StudySessionModel.formatDuration(
          const Duration(hours: 25, minutes: 59, seconds: 59),
        ),
        '25:59:59',
      );
      expect(StudySessionModel.formatDuration(Duration.zero), '00:00:00');
    });
  });
}
