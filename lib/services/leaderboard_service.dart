import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';
import 'subject_service.dart';

class LeaderboardService {
  static final _client = Supabase.instance.client;

  // ─── Offline leaderboards (completed sessions only) ──────────────────────

  static Future<List<LeaderboardEntry>> getDailyLeaderboard() =>
      _fetch('leaderboard_daily');

  static Future<List<LeaderboardEntry>> getWeeklyLeaderboard() =>
      _fetch('leaderboard_weekly');

  static Future<List<LeaderboardEntry>> getMonthlyLeaderboard() =>
      _fetch('leaderboard_monthly');

  static Future<List<LeaderboardEntry>> getAllTimeLeaderboard() =>
      _fetch('leaderboard_all_time');

  static Future<List<LeaderboardEntry>> _fetch(String viewName) async {
    final data = await _client.from(viewName).select();
    return (data as List<dynamic>)
        .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ─── Personal stats for current user ─────────────────────────────────────

  /// Compute stats for [userId] across all time windows from study_sessions.
  /// All windows use ONLY completed (is_active=false, end_time IS NOT NULL) sessions.
  static Future<UserStats> getUserStats(String userId) async {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final startOfMonth = DateTime.utc(now.year, now.month, 1);

    final data = await _client
        .from('study_sessions')
        .select('start_time, end_time, subject') // fetch subject too
        .eq('user_id', userId)
        .eq('is_active', false)
        .not('end_time', 'is', null);

    final rows = data as List<dynamic>;

    double dailySeconds = 0;
    double weeklySeconds = 0;
    double monthlySeconds = 0;
    double totalSeconds = 0;

    // Aggregation for the subject breakdown.
    // Keys are normalised lowercase; bucketed as 'others' if non-standard.
    final Map<String, double> subjectSecs = {};
    
    final standardSubjects = await SubjectService.getSubjects();
    final standardKeys = standardSubjects.map((e) => e.key).toSet();

    for (final row in rows) {
      final start = DateTime.parse(row['start_time'] as String).toUtc();
      final end = DateTime.parse(row['end_time'] as String).toUtc();
      final secs = end.difference(start).inSeconds.toDouble();
      if (secs <= 0) continue;

      totalSeconds += secs;
      if (start.isAfter(startOfMonth)) monthlySeconds += secs;
      if (start.isAfter(sevenDaysAgo)) weeklySeconds += secs;
      if (start.isAfter(startOfDay)) dailySeconds += secs;

      // --- Subject aggregation (Store Truth, Filter for View) ---
      final rawSubject = (row['subject'] as String?)?.trim().toLowerCase();
      final key = (rawSubject != null && standardKeys.contains(rawSubject))
          ? rawSubject
          : 'others';
      subjectSecs[key] = (subjectSecs[key] ?? 0) + secs;
    }

    // Convert seconds → hours for all subject buckets.
    final subjectHours = subjectSecs
        .map((k, v) => MapEntry(k, double.parse((v / 3600).toStringAsFixed(2))));

    return UserStats(
      daily: dailySeconds / 3600,
      weekly: weeklySeconds / 3600,
      monthly: monthlySeconds / 3600,
      total: totalSeconds / 3600,
      subjectBreakdown: subjectHours,
    );
  }

  // ─── Username management ──────────────────────────────────────────────────

  /// Get the current user's profile username.
  static Future<String?> getMyUsername() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('profiles')
        .select('username')
        .eq('id', uid)
        .maybeSingle();
    return data?['username'] as String?;
  }

  /// Update the current user's username.
  static Future<void> updateUsername(String username) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('profiles')
        .upsert({'id': uid, 'username': username, 'updated_at': DateTime.now().toUtc().toIso8601String()});
  }
}
