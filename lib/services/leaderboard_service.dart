import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry_model.dart';

class StatsLoadException implements Exception {
  final String message;

  const StatsLoadException(this.message);

  @override
  String toString() => message;
}

class LeaderboardService {
  static final _client = Supabase.instance.client;

  // Offline leaderboards (completed sessions only)

  static Future<List<LeaderboardEntry>> getDailyLeaderboard() =>
      _fetch('leaderboard_daily');

  static Future<List<LeaderboardEntry>> getWeeklyLeaderboard() =>
      _fetch('leaderboard_weekly');

  static Future<List<LeaderboardEntry>> getMonthlyLeaderboard() =>
      _fetch('leaderboard_monthly');

  static Future<List<LeaderboardEntry>> getAllTimeLeaderboard() =>
      _fetch('leaderboard_all_time');

  static Future<List<LeaderboardEntry>> _fetch(String viewName) async {
    // M3 fix: cap at 100 rows so the full view is not transferred on every poll.
    final data = await _client.from(viewName).select().limit(100);
    return (data as List<dynamic>)
        .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Personal stats for current user

  /// Fetches boundary-correct personal stats via the [get_my_stats] DB RPC.
  ///
  /// [userId] is kept in the signature for call-site compatibility but is
  /// ignored. The RPC enforces the current user's identity server-side.
  static Future<UserStats> getUserStats(String userId) async {
    final data = await _client.rpc('get_my_stats');
    if (data == null) {
      throw const StatsLoadException('Stats are unavailable right now.');
    }
    if (data is! Map<String, dynamic>) {
      throw const StatsLoadException('Stats response was invalid.');
    }

    final Map<String, double> subjectBreakdown = {};
    final rawBreakdown = data['subject_breakdown'];
    try {
      if (rawBreakdown is Map) {
        rawBreakdown.forEach((k, v) {
          subjectBreakdown[k as String] = (v as num).toDouble();
        });
      }

      return UserStats(
        daily: (data['daily'] as num?)?.toDouble() ?? 0,
        weekly: (data['weekly'] as num?)?.toDouble() ?? 0,
        monthly: (data['monthly'] as num?)?.toDouble() ?? 0,
        total: (data['total'] as num?)?.toDouble() ?? 0,
        subjectBreakdown: subjectBreakdown,
      );
    } catch (_) {
      throw const StatsLoadException('Stats response could not be parsed.');
    }
  }

  // Username management

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
    await _client.from('profiles').upsert({
      'id': uid,
      'username': username,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
