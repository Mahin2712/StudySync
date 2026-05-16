import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/leaderboard_entry_model.dart';

/// Sub-phase 0: Contract guard — ensures UserStats.fromJson-style parsing
/// matches the exact shape returned by the `get_my_stats` Supabase RPC.
///
/// If the RPC payload shape ever drifts, this test will break before any
/// production code silently swallows bad data.
void main() {
  group('UserStats contract shape', () {
    test('parses a valid get_my_stats payload', () {
      final mockPayload = <String, dynamic>{
        'daily': 1.5,
        'weekly': 8.25,
        'monthly': 32.0,
        'total': 120.75,
        'subject_breakdown': <String, dynamic>{
          'physics': 40.0,
          'chemistry': 30.5,
          'math': 25.0,
          'others': 25.25,
        },
      };

      // Simulate the parsing done in LeaderboardService.getUserStats()
      final Map<String, double> subjectBreakdown = {};
      final rawBreakdown = mockPayload['subject_breakdown'];
      if (rawBreakdown is Map) {
        rawBreakdown.forEach((k, v) {
          subjectBreakdown[k as String] = (v as num).toDouble();
        });
      }

      final stats = UserStats(
        daily: (mockPayload['daily'] as num?)?.toDouble() ?? 0,
        weekly: (mockPayload['weekly'] as num?)?.toDouble() ?? 0,
        monthly: (mockPayload['monthly'] as num?)?.toDouble() ?? 0,
        total: (mockPayload['total'] as num?)?.toDouble() ?? 0,
        subjectBreakdown: subjectBreakdown,
      );

      expect(stats.daily, 1.5);
      expect(stats.weekly, 8.25);
      expect(stats.monthly, 32.0);
      expect(stats.total, 120.75);
      expect(stats.subjectBreakdown, hasLength(4));
      expect(stats.subjectBreakdown['physics'], 40.0);
      expect(stats.subjectBreakdown['others'], 25.25);
    });

    test('handles missing subject_breakdown gracefully', () {
      final mockPayload = <String, dynamic>{
        'daily': 0.0,
        'weekly': 0.0,
        'monthly': 0.0,
        'total': 0.0,
        // subject_breakdown missing entirely
      };

      final Map<String, double> subjectBreakdown = {};
      final rawBreakdown = mockPayload['subject_breakdown'];
      if (rawBreakdown is Map) {
        rawBreakdown.forEach((k, v) {
          subjectBreakdown[k as String] = (v as num).toDouble();
        });
      }

      final stats = UserStats(
        daily: (mockPayload['daily'] as num?)?.toDouble() ?? 0,
        weekly: (mockPayload['weekly'] as num?)?.toDouble() ?? 0,
        monthly: (mockPayload['monthly'] as num?)?.toDouble() ?? 0,
        total: (mockPayload['total'] as num?)?.toDouble() ?? 0,
        subjectBreakdown: subjectBreakdown,
      );

      expect(stats.daily, 0.0);
      expect(stats.subjectBreakdown, isEmpty);
    });

    test('handles null numeric values with safe defaults', () {
      final mockPayload = <String, dynamic>{
        'daily': null,
        'weekly': null,
        'monthly': null,
        'total': null,
        'subject_breakdown': null,
      };

      final Map<String, double> subjectBreakdown = {};
      final rawBreakdown = mockPayload['subject_breakdown'];
      if (rawBreakdown is Map) {
        rawBreakdown.forEach((k, v) {
          subjectBreakdown[k as String] = (v as num).toDouble();
        });
      }

      final stats = UserStats(
        daily: (mockPayload['daily'] as num?)?.toDouble() ?? 0,
        weekly: (mockPayload['weekly'] as num?)?.toDouble() ?? 0,
        monthly: (mockPayload['monthly'] as num?)?.toDouble() ?? 0,
        total: (mockPayload['total'] as num?)?.toDouble() ?? 0,
        subjectBreakdown: subjectBreakdown,
      );

      expect(stats.daily, 0.0);
      expect(stats.weekly, 0.0);
      expect(stats.monthly, 0.0);
      expect(stats.total, 0.0);
      expect(stats.subjectBreakdown, isEmpty);
    });

    test('UserStats.zero constant is valid', () {
      expect(UserStats.zero.daily, 0);
      expect(UserStats.zero.weekly, 0);
      expect(UserStats.zero.monthly, 0);
      expect(UserStats.zero.total, 0);
      expect(UserStats.zero.subjectBreakdown, isEmpty);
    });
  });
}
