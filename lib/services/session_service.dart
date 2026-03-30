import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_session_model.dart';

class SessionService {
  static final _client = Supabase.instance.client;

  static String get _uid => _client.auth.currentUser!.id;

  // ─── Start session ────────────────────────────────────────────────────────

  /// Starts a new study session. Sets last_activity_at = now (UTC).
  /// Returns existing session without inserting if one is already active.
  static Future<StudySessionModel?> startSession(
    String roomId, {
    String? subject,
  }) async {
    // Duplicate guard
    final existing = await getActiveSessionForUser();
    if (existing != null) return existing;

    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('study_sessions')
        .insert({
          'user_id': _uid,
          'room_id': roomId,
          'subject': subject,
          'start_time': now,
          'is_active': true,
          'last_activity_at': now,
        })
        .select()
        .single();

    return StudySessionModel.fromJson(data);
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
    // Fetch current count first (Supabase REST doesn't support column expressions)
    final existing = await _client
        .from('study_sessions')
        .select('missed_checkins')
        .eq('user_id', _uid)
        .eq('is_active', true)
        .maybeSingle();

    if (existing == null) return; // Already stopped — nothing to do.

    final currentMissed = (existing['missed_checkins'] as int?) ?? 0;

    await _client
        .from('study_sessions')
        .update({
          'is_active': false,
          'end_time': DateTime.now().toUtc().toIso8601String(),
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
}
