import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/profile_model.dart';

void main() {
  group('ProfileModel.initials', () {
    test('returns "?" for empty display name', () {
      final profile = ProfileModel(
        id: '1',
        username: '',
        profileComplete: false,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, '?');
    });

    test('returns "?" for whitespace-only display name', () {
      final profile = ProfileModel(
        id: '1',
        username: '   ',
        profileComplete: false,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, '?');
    });

    test('returns initials for two-word student name', () {
      final profile = ProfileModel(
        id: '1',
        username: 'johndoe',
        studentName: 'John Doe',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'JD');
    });

    test('returns initials for two-word username when student name is null', () {
      final profile = ProfileModel(
        id: '1',
        username: 'jane smith',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'JS');
    });

    test('returns initials for names separated by underscores', () {
      final profile = ProfileModel(
        id: '1',
        username: 'alice_wonderland',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'AW');
    });

    test('returns initials for names with multiple spaces', () {
      final profile = ProfileModel(
        id: '1',
        username: 'Bob    Builder',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'BB');
    });

    test('returns first two letters for single-word name', () {
      final profile = ProfileModel(
        id: '1',
        username: 'Charlie',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'CH');
    });

    test('returns first letter for single-character name', () {
      final profile = ProfileModel(
        id: '1',
        username: 'D',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'D');
    });

    test('returns uppercase initials', () {
      final profile = ProfileModel(
        id: '1',
        username: 'eve online',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'EO');
    });

    test('studentName takes precedence over username for initials', () {
      final profile = ProfileModel(
        id: '1',
        username: 'original_user',
        studentName: 'Real Name',
        profileComplete: true,
        createdAt: DateTime.now(),
      );
      expect(profile.initials, 'RN');
    });
  });
}
