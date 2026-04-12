import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/leaderboard_entry_model.dart';

void main() {
  group('LeaderboardEntry', () {
    const userId = 'user-123';
    const totalHours = 10.5;

    group('initials', () {
      test('returns JD for john_doe', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'john_doe',
          totalHours: totalHours,
        );
        expect(entry.initials, 'JD');
      });

      test('returns AL for alice', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'alice',
          totalHours: totalHours,
        );
        expect(entry.initials, 'AL');
      });

      test('returns A for a', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'a',
          totalHours: totalHours,
        );
        expect(entry.initials, 'A');
      });

      test('returns ? for empty username', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: '',
          totalHours: totalHours,
        );
        expect(entry.initials, '?');
      });

      test('returns ? for whitespace username', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: '   ',
          totalHours: totalHours,
        );
        expect(entry.initials, '?');
      });

      test('returns AB for a_b_c', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'a_b_c',
          totalHours: totalHours,
        );
        expect(entry.initials, 'AB');
      });

      test('returns _U for _user', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: '_user',
          totalHours: totalHours,
        );
        expect(entry.initials, '_U');
      });

      test('returns US for user_', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user_',
          totalHours: totalHours,
        );
        expect(entry.initials, 'US');
      });

      test('trims username before processing', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: '  jane_doe  ',
          totalHours: totalHours,
        );
        expect(entry.initials, 'JD');
      });

      test('handles mixed case usernames', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'John_Doe',
          totalHours: totalHours,
        );
        expect(entry.initials, 'JD');
      });
    });

    group('formattedHours', () {
      test('returns 0m for 0 hours', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user',
          totalHours: 0,
        );
        expect(entry.formattedHours, '0m');
      });

      test('returns 30m for 0.5 hours', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user',
          totalHours: 0.5,
        );
        expect(entry.formattedHours, '30m');
      });

      test('returns 1h for 1 hour', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user',
          totalHours: 1.0,
        );
        expect(entry.formattedHours, '1h');
      });

      test('returns 1h 30m for 1.5 hours', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user',
          totalHours: 1.5,
        );
        expect(entry.formattedHours, '1h 30m');
      });

      test('rounds minutes correctly', () {
        const entry = LeaderboardEntry(
          userId: userId,
          username: 'user',
          totalHours: 1.3333,
        );
        // 0.3333 * 60 = 19.998 -> 20
        expect(entry.formattedHours, '1h 20m');
      });
    });
  });
}
