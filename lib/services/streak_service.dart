import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Immutable snapshot of a user's streak data.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String? lastStudyDate;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: (json['current_streak'] as num?)?.toInt() ??
          (json['current_streak_days'] as num?)?.toInt() ??
          0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ??
          (json['longest_streak_days'] as num?)?.toInt() ??
          0,
      lastStudyDate: json['last_study_date'] as String?,
    );
  }

  static const zero = StreakData();
}

/// Service for reading and updating the user's study streak.
class StreakService {
  static final _client = Supabase.instance.client;

  /// Fetches current streak info from the profiles table.
  static Future<StreakData> getStreak() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return StreakData.zero;

    final data = await _client
        .from('profiles')
        .select('current_streak_days, longest_streak_days, last_study_date')
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return StreakData.zero;
    return StreakData.fromJson(data);
  }

  /// Calls the update_streak RPC after a session ends.
  /// Should be called from SessionService.stopSession() flow.
  /// Returns updated streak data.
  static Future<StreakData> updateStreak() async {
    try {
      final data = await _client.rpc('update_streak');
      if (data == null || data is! Map<String, dynamic>) {
        return StreakData.zero;
      }
      return StreakData.fromJson(data);
    } catch (e) {
      debugPrint('[StreakService] updateStreak failed: $e');
      return StreakData.zero;
    }
  }
}
