class ProfileModel {
  final String id;
  final String username;
  final String? studentName;
  final String? schoolName;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool profileComplete;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Phase 6: Gamification fields
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastStudyDate;
  final int dailyGoalMinutes;

  const ProfileModel({
    required this.id,
    required this.username,
    this.studentName,
    this.schoolName,
    this.phoneNumber,
    this.avatarUrl,
    required this.profileComplete,
    required this.createdAt,
    this.updatedAt,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastStudyDate,
    this.dailyGoalMinutes = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? 'user_???',
      studentName: json['student_name'] as String?,
      schoolName: json['school_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileComplete: (json['profile_complete'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      // Phase 6: streak + goal fields (safe defaults for old profiles)
      currentStreakDays:
          (json['current_streak_days'] as num?)?.toInt() ?? 0,
      longestStreakDays:
          (json['longest_streak_days'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['last_study_date'] as String?,
      dailyGoalMinutes:
          (json['daily_goal_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Display name: student name if set, otherwise username.
  String get displayName =>
      (studentName != null && studentName!.isNotEmpty) ? studentName! : username;

  /// Initials for avatar circles.
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }
}
