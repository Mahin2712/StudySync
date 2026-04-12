import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/profile_model.dart';

void main() {
  group('ProfileModel', () {
    final now = DateTime.now();

    test('should initialize with constructor', () {
      final profile = ProfileModel(
        id: '123',
        username: 'johndoe',
        studentName: 'John Doe',
        schoolName: 'Test School',
        phoneNumber: '123456789',
        avatarUrl: 'https://example.com/avatar.png',
        profileComplete: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.id, '123');
      expect(profile.username, 'johndoe');
      expect(profile.studentName, 'John Doe');
      expect(profile.schoolName, 'Test School');
      expect(profile.phoneNumber, '123456789');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.profileComplete, true);
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
    });

    test('should create from json with all fields', () {
      final json = {
        'id': '123',
        'username': 'johndoe',
        'student_name': 'John Doe',
        'school_name': 'Test School',
        'phone_number': '123456789',
        'avatar_url': 'https://example.com/avatar.png',
        'profile_complete': true,
        'created_at': '2023-01-01T10:00:00Z',
        'updated_at': '2023-01-01T11:00:00Z',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, '123');
      expect(profile.username, 'johndoe');
      expect(profile.studentName, 'John Doe');
      expect(profile.profileComplete, true);
      // We don't check exact time due to toLocal() conversion, but we check it's parsed
      expect(profile.createdAt, isA<DateTime>());
      expect(profile.updatedAt, isNotNull);
    });

    test('should create from json with minimal fields and use defaults', () {
      final json = {
        'id': '123',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, '123');
      expect(profile.username, 'user_???');
      expect(profile.profileComplete, false);
      expect(profile.studentName, isNull);
      expect(profile.createdAt, isA<DateTime>());
      expect(profile.updatedAt, isNull);
    });

    group('displayName', () {
      test('should return studentName if set and not empty', () {
        final profile = ProfileModel(
          id: '1',
          username: 'user1',
          studentName: 'Real Name',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.displayName, 'Real Name');
      });

      test('should return username if studentName is null', () {
        final profile = ProfileModel(
          id: '1',
          username: 'user1',
          studentName: null,
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.displayName, 'user1');
      });

      test('should return username if studentName is empty', () {
        final profile = ProfileModel(
          id: '1',
          username: 'user1',
          studentName: '',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.displayName, 'user1');
      });
    });

    group('initials', () {
      test('should return first letters of first and last name', () {
        final profile = ProfileModel(
          id: '1',
          username: 'johndoe',
          studentName: 'John Doe',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, 'JD');
      });

      test('should handle underscores as separators', () {
        final profile = ProfileModel(
          id: '1',
          username: 'john_doe',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, 'JD');
      });

      test('should return first two letters for single name', () {
        final profile = ProfileModel(
          id: '1',
          username: 'Alice',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, 'AL');
      });

      test('should return one letter if name is only one character', () {
        final profile = ProfileModel(
          id: '1',
          username: 'A',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, 'A');
      });

      test('should return ? for empty name', () {
        final profile = ProfileModel(
          id: '1',
          username: '',
          studentName: '',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, '?');
      });

      test('should handle multiple spaces and trim', () {
        final profile = ProfileModel(
          id: '1',
          username: '  John   Doe  ',
          profileComplete: true,
          createdAt: now,
        );
        expect(profile.initials, 'JD');
      });
    });
  });
}
