import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/profile_model.dart';

void main() {
  group('ProfileModel.initials', () {
    test('should return ? when name is empty', () {
      final profile = ProfileModel(
        id: '1',
        username: '',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, '?');
    });

    test('should return two initials for space-separated names', () {
      final profile = ProfileModel(
        id: '1',
        username: 'mahin',
        studentName: 'Mahin Ahmed',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'MA');
    });

    test('should return two initials for underscore-separated names', () {
      final profile = ProfileModel(
        id: '1',
        username: 'mahin_ahmed',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'MA');
    });

    test('should return first two letters for single names', () {
      final profile = ProfileModel(
        id: '1',
        username: 'mahin',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'MA');
    });

    test('should handle multiple spaces and underscores', () {
      final profile = ProfileModel(
        id: '1',
        username: 'mahin__ahmed  test',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'MA');
    });
  });
}
