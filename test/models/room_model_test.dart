import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/room_model.dart';

void main() {
  group('RoomModel', () {
    final now = DateTime.now();

    test('should correctly initialize with constructor', () {
      final room = RoomModel(
        id: '1',
        name: 'Test Room',
        createdBy: 'user1',
        createdAt: now,
        subject: 'Math',
        isCustom: true,
        memberCount: 5,
      );

      expect(room.id, '1');
      expect(room.name, 'Test Room');
      expect(room.createdBy, 'user1');
      expect(room.createdAt, now);
      expect(room.subject, 'Math');
      expect(room.isCustom, true);
      expect(room.memberCount, 5);
    });

    test('should use default memberCount of 0', () {
      final room = RoomModel(
        id: '1',
        name: 'Test Room',
        createdBy: 'user1',
        createdAt: now,
        subject: 'Math',
        isCustom: true,
      );

      expect(room.memberCount, 0);
    });

    group('fromJson', () {
      test('should parse correctly with all fields present', () {
        final json = {
          'id': 'room-123',
          'name': 'Physics Study Group',
          'created_by': 'user-456',
          'created_at': '2023-10-27T10:00:00Z',
          'subject': 'Physics',
          'is_custom': false,
        };

        final room = RoomModel.fromJson(json);

        expect(room.id, 'room-123');
        expect(room.name, 'Physics Study Group');
        expect(room.createdBy, 'user-456');
        expect(room.createdAt, DateTime.parse('2023-10-27T10:00:00Z'));
        expect(room.subject, 'Physics');
        expect(room.isCustom, false);
      });

      test('should use default values for missing optional fields', () {
        final json = {
          'id': 'room-789',
          'created_at': '2023-10-27T11:00:00Z',
        };

        final room = RoomModel.fromJson(json);

        expect(room.id, 'room-789');
        expect(room.name, 'Unnamed Room');
        expect(room.createdBy, '');
        expect(room.createdAt, DateTime.parse('2023-10-27T11:00:00Z'));
        expect(room.subject, 'Others');
        expect(room.isCustom, true);
      });

      test('should throw FormatException if created_at is not a valid date', () {
        final json = {
          'id': 'room-abc',
          'created_at': 'not-a-date',
        };

        expect(() => RoomModel.fromJson(json), throwsA(isA<FormatException>()));
      });
    });
  });
}
