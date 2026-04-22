enum CheckinStatus { active, warning }

class StudySessionModel {
  final String id;
  final String userId;
  final String roomId;
  final String? deviceId;
  final String? deviceType;
  final String? subject;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final int missedCheckins;

  /// How long between check-ins — single source of truth.
  static const checkinInterval = Duration(minutes: 20);

  /// Grace window after the check-in interval before auto-stop fires.
  static const checkinGrace = Duration(seconds: 60);

  const StudySessionModel({
    required this.id,
    required this.userId,
    required this.roomId,
    this.deviceId,
    this.deviceType,
    this.subject,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.createdAt,
    this.lastActivityAt,
    this.missedCheckins = 0,
  });

  /// Always computed from DB start_time → never stored incrementally.
  Duration get elapsed => DateTime.now().toUtc().difference(startTime.toUtc());

  /// How long ago the user last confirmed activity.
  /// This is the SINGLE SOURCE OF TRUTH for check-in decisions.
  Duration get timeSinceActivity {
    final ref = lastActivityAt ?? startTime;
    return DateTime.now().toUtc().difference(ref.toUtc());
  }

  /// True if the check-in popup should be shown.
  bool get isCheckinDue => timeSinceActivity >= checkinInterval;

  /// True if the session should be auto-stopped (interval + full grace elapsed).
  bool get isAutoStopDue => timeSinceActivity >= checkinInterval + checkinGrace;

  /// Derived convenience — NOT stored in DB.
  DateTime? get nextCheckinAt => lastActivityAt?.toUtc().add(checkinInterval);

  /// Active = check-in not yet due. Warning = check-in overdue.
  CheckinStatus get checkinStatus {
    if (lastActivityAt == null) return CheckinStatus.active;
    return timeSinceActivity >= checkinInterval
        ? CheckinStatus.warning
        : CheckinStatus.active;
  }

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      deviceId: json['device_id'] as String?,
      deviceType: json['device_type'] as String?,
      subject: json['subject'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toUtc(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String).toUtc()
          : null,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String).toUtc()
          : null,
      missedCheckins: json['missed_checkins'] as int? ?? 0,
    );
  }

  /// Format elapsed duration as HH:MM:SS.
  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
