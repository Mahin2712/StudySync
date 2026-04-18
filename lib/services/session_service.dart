import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_session_model.dart';

class SessionService {
  static final _client = Supabase.instance.client;

  static String get _uid => _client.auth.currentUser!.id;

  // ─── Start session ────────────────────────────────────────────────────────

  /// Starts a new study session atomically via a DB RPC.
  ///
  /// Uses [start_session_atomic] which:
  ///   • Attempts INSERT ... ON CONFLICT DO NOTHING (race-safe).
  ///   • Always returns the single active session row.
  ///   • Enforced by a partial unique index (user_id WHERE is_active=true).
  ///
  /// Returns the existing session if one is already active — no duplicate
  /// rows can be created even under concurrent tab/device access.
  static Future<StudySessionModel?> startSession(
    String roomId, {
    String? subject,
    String? chapter,
  }) async {
    final data = await _client.rpc(
      'start_session_atomic',
      params: {
        'p_room_id': roomId,
        'p_subject': subject,
        'p_chapter': chapter,
      },
    );
    if (data == null) return null;
    return StudySessionModel.fromJson(data as Map<String, dynamic>);
  }


  // ─── Stop session ─────────────────────────────────────────────────────────

  /// Stops the current user's active session.
  static Future<void> stopSession() async {
    await _client
        .from('study_sessions')
        .update({
          'is_active': false,
          'end_time': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('is_active', true);
  }

  // ─── Auto-stop (missed check-in) ──────────────────────────────────────────

  /// Stops session and increments missed_checkins by 1.
  static Future<void> autoStopSession() async {
    // Fetch both missed_checkins and last_activity_at.
    // We use last_activity_at as end_time so the user is only credited for
    // the time they were *confirmed present* — not the unconfirmed tail segment.
    final existing = await _client
        .from('study_sessions')
        .select('missed_checkins, last_activity_at')
        .eq('user_id', _uid)
        .eq('is_active', true)
        .maybeSingle();

    if (existing == null) return; // Already stopped — nothing to do.

    final currentMissed = (existing['missed_checkins'] as int?) ?? 0;

    // Prefer last_activity_at as the honest end_time; fall back to now() only
    // if the column is somehow null (e.g. very old rows).
    final endTime = existing['last_activity_at'] != null
        ? existing['last_activity_at'] as String
        : DateTime.now().toUtc().toIso8601String();

    await _client
        .from('study_sessions')
        .update({
          'is_active': false,
          'end_time': endTime,
          'missed_checkins': currentMissed + 1,
        })
        .eq('user_id', _uid)
        .eq('is_active', true);
  }

  // ─── Confirm check-in ─────────────────────────────────────────────────────

  /// User tapped "Yes, I'm still here". Resets the activity clock.
  /// Returns the updated session.
  static Future<StudySessionModel?> confirmCheckin() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('study_sessions')
        .update({'last_activity_at': now})
        .eq('user_id', _uid)
        .eq('is_active', true)
        .select()
        .maybeSingle();

    if (data == null) return null;
    return StudySessionModel.fromJson(data);
  }

  // ─── Record activity (future: chat / emoji / sticker) ─────────────────────

  /// Call this whenever the user does ANY active thing (chat, emoji, etc.)
  /// to reset the inactivity clock without showing the check-in popup.
  static Future<void> recordActivity() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('study_sessions')
        .update({'last_activity_at': now})
        .eq('user_id', _uid)
        .eq('is_active', true);
  }

  // ─── Fetch current user's active session ─────────────────────────────────

  static Future<StudySessionModel?> getActiveSessionForUser() async {
    final data = await _client
        .from('study_sessions')
        .select()
        .eq('user_id', _uid)
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return StudySessionModel.fromJson(data);
  }

  // ─── Fetch all active sessions in a room ─────────────────────────────────

  static Future<List<StudySessionModel>> getActiveSessions(
      String roomId) async {
    final data = await _client
        .from('study_sessions')
        .select()
        .eq('room_id', roomId)
        .eq('is_active', true)
        .order('start_time', ascending: true);

    return (data as List<dynamic>)
        .map((j) => StudySessionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ─── Force-close active session (ghost-session prevention) ───────────────

  /// Force-closes any currently active session for this user.
  ///
  /// Uses [last_activity_at] as [end_time] so the user only gets credit
  /// for time they were confirmed present — not the unconfirmed tail.
  ///
  /// Called when:
  ///   • Joining a different room (room-hopping)
  ///   • Leaving a room manually
  ///   • Back-navigation out of RoomDetailScreen
  ///
  /// ⚠️ MVP limitation: this closes ALL active sessions for this user,
  /// including sessions from other devices. Multi-device support (device_id
  /// column) is planned for Phase 3.x.
  static Future<void> forceCloseActiveSession() async {
    final existing = await _client
        .from('study_sessions')
        .select('last_activity_at')
        .eq('user_id', _uid)
        .eq('is_active', true)
        .maybeSingle();

    if (existing == null) return; // Nothing active — no-op.

    final endTime = existing['last_activity_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();

    await _client
        .from('study_sessions')
        .update({
          'is_active': false,
          'end_time': endTime,
        })
        .eq('user_id', _uid)
        .eq('is_active', true);
  }

  // ─── Stale-session cleanup (pg_cron fallback) ─────────────────────────────

  /// Triggers the [close_stale_sessions] DB function client-side.
  ///
  /// This is the fallback for Supabase free-tier where pg_cron may be
  /// unavailable. Called fire-and-forget on app startup from [main.dart].
  ///
  /// The DB function marks sessions inactive where
  /// [last_activity_at] < NOW() - 25 minutes.
  static Future<void> cleanUpStaleSessions() async {
    try {
      await _client.rpc('close_stale_sessions');
    } catch (_) {
      // Best-effort — never block app startup.
    }
  }
}
