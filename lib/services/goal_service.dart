import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Progress toward the user's daily study goal.
class GoalProgress {
  final int goalMinutes; // 0 if not set
  final double studiedMinutes; // from daily stats
  final bool isGoalMet;

  const GoalProgress({
    this.goalMinutes = 0,
    this.studiedMinutes = 0,
    this.isGoalMet = false,
  });

  static const zero = GoalProgress();
}

/// Service for reading/writing the user's daily study goal.
class GoalService {
  static final _client = Supabase.instance.client;

  /// Get the user's daily goal in minutes (0 = no goal set).
  static Future<int> getDailyGoal() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;

    final data = await _client
        .from('profiles')
        .select('daily_goal_minutes')
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return 0;
    return (data['daily_goal_minutes'] as num?)?.toInt() ?? 0;
  }

  /// Set/update the daily goal (persists to profiles table).
  static Future<void> setDailyGoal(int minutes) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client
        .from('profiles')
        .update({
          'daily_goal_minutes': minutes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', uid);
  }

  /// Get today's progress toward the daily goal.
  /// Returns minutes studied today (from get_my_stats daily hours × 60)
  /// combined with the goal setting from the profile.
  static Future<GoalProgress> getTodayProgress() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return GoalProgress.zero;

      // Fetch goal and daily stats in parallel
      final goalFuture = _client
          .from('profiles')
          .select('daily_goal_minutes')
          .eq('id', uid)
          .maybeSingle();

      final statsFuture = _client.rpc('get_my_stats');

      final goalData = await goalFuture;
      final statsData = await statsFuture;

      final goalMinutes =
          (goalData?['daily_goal_minutes'] as num?)?.toInt() ?? 0;

      // get_my_stats returns daily as hours (double)
      double dailyHours = 0;
      if (statsData != null && statsData is Map<String, dynamic>) {
        dailyHours = (statsData['daily'] as num?)?.toDouble() ?? 0;
      }
      final studiedMinutes = dailyHours * 60;

      return GoalProgress(
        goalMinutes: goalMinutes,
        studiedMinutes: studiedMinutes,
        isGoalMet: goalMinutes > 0 && studiedMinutes >= goalMinutes,
      );
    } catch (e) {
      debugPrint('[GoalService] getTodayProgress failed: $e');
      return GoalProgress.zero;
    }
  }
}
