/// A single ranked entry returned from any leaderboard view.
class LeaderboardEntry {
  final String userId;
  final String username;
  final double totalHours;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalHours,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: (json['username'] as String?) ?? 'Studier',
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Returns the first 1–2 characters of the username as initials for avatars.
  String get initials {
    final parts = username.trim().split('_');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return username.trim().isEmpty
        ? '?'
        : username.trim().substring(0, username.trim().length.clamp(1, 2)).toUpperCase();
  }

  /// Format hours as "Xh Ym" or "Xm" if less than 1 hour.
  String get formattedHours {
    if (totalHours <= 0) return '0m';
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// Personal stats for the current user across all time windows.
class UserStats {
  final double daily;
  final double weekly;
  final double monthly;
  final double total;

  /// Hours per subject (Dashboard view).
  /// Non-standard subjects are bucketed under the key 'others'.
  final Map<String, double> subjectBreakdown;

  const UserStats({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.total,
    this.subjectBreakdown = const {},
  });

  static const zero = UserStats(daily: 0, weekly: 0, monthly: 0, total: 0);
}
