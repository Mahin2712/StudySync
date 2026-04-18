import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';

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

  /// Fetches boundary-correct personal stats via the [get_my_stats] DB RPC.
  ///
  /// The RPC:
  ///   • Clips sessions to window boundaries with GREATEST/LEAST so a session
  ///     spanning midnight is proportionally credited to both days.
  ///   • Derives identity from auth.uid() — no user can read another's stats.
  ///   • Returns subject_breakdown so [UserStats.subjectBreakdown] is preserved.
  ///
  /// [userId] is kept in the signature for call-site compatibility but is
  /// ignored — the RPC enforces the current user's identity server-side.
  static Future<UserStats> getUserStats(String userId) async {
    try {
      final data = await _client.rpc('get_my_stats');
      if (data == null) return UserStats.zero;

      final json = data as Map<String, dynamic>;

      // Rebuild subjectBreakdown from the JSON object.
      final Map<String, double> subjectBreakdown = {};
      final rawBreakdown = json['subject_breakdown'];
      if (rawBreakdown is Map) {
        rawBreakdown.forEach((k, v) {
          subjectBreakdown[k as String] = (v as num).toDouble();
        });
      }

      return UserStats(
        daily:            (json['daily']   as num?)?.toDouble() ?? 0,
        weekly:           (json['weekly']  as num?)?.toDouble() ?? 0,
        monthly:          (json['monthly'] as num?)?.toDouble() ?? 0,
        total:            (json['total']   as num?)?.toDouble() ?? 0,
        subjectBreakdown: subjectBreakdown,
      );
    } catch (_) {
      return UserStats.zero;
    }
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
