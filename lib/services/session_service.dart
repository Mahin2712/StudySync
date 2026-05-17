import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_session_model.dart';
import 'device_identity_service.dart';
import 'streak_service.dart';

class SessionService {
  static final _client = Supabase.instance.client;

  static String get _uid => _client.auth.currentUser!.id;
  static Future<String> getCurrentDeviceId() =>
      DeviceIdentityService.getDeviceId();

  // Start session

  /// Starts a new study session atomically via a DB RPC.
  ///
  /// Uses [start_session_atomic] which:
  ///   - Attempts INSERT ... ON CONFLICT DO NOTHING (race-safe).
  ///   - Always returns the single active session row for this device.
  ///   - Is enforced by a partial unique index on (user_id, device_id).
  static Future<StudySessionModel?> startSession(
    String roomId, {
    String? subject,
    String? chapter,
  }) async {
    final deviceId = await getCurrentDeviceId();
    final deviceType = _getDeviceType();
    final data = await _client.rpc(
      'start_session_atomic',
      params: {
        'p_room_id': roomId,
        'p_subject': subject,
        'p_chapter': chapter,
        'p_device_id': deviceId,
        'p_device_type': deviceType,
      },
    );
    if (data == null) return null;
    return StudySessionModel.fromJson(data as Map<String, dynamic>);
  }

  static String _getDeviceType() {
    if (kIsWeb) return 'pc';
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return 'pc';

    // For mobile/tablet, check logical screen width
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      if (logicalWidth >= 600) return 'tablet';
      return 'mobile';
    } catch (_) {
      // Fallback
      return 'mobile';
    }
  }

  // Stop session

  /// Stops the current device's active session.
  static Future<void> stopSession() async {
    final deviceId = await getCurrentDeviceId();
    await _client
        .from('study_sessions')
        .update({
          'is_active': false,
          'end_time': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true);

    // Phase 6: Fire-and-forget streak update after session stop.
    // Streak update failure must never block the session stop flow.
    StreakService.updateStreak().catchError((e) {
      debugPrint('[SessionService] Streak update after stopSession failed: $e');
      return StreakData.zero;
    });
  }

  // Auto-stop (missed check-in)

  /// Stops this device's session and increments missed_checkins by 1.
  static Future<void> autoStopSession() async {
    final deviceId = await getCurrentDeviceId();
    final existing = await _client
        .from('study_sessions')
        .select('missed_checkins, last_activity_at')
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true)
        .maybeSingle();

    if (existing == null) return;

    final currentMissed = (existing['missed_checkins'] as int?) ?? 0;
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
        .eq('device_id', deviceId)
        .eq('is_active', true);
  }

  // Confirm check-in

  /// User tapped "Yes, I'm still here". Resets the activity clock.
  /// Returns the updated session for this device.
  static Future<StudySessionModel?> confirmCheckin() async {
    final deviceId = await getCurrentDeviceId();
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('study_sessions')
        .update({'last_activity_at': now})
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true)
        .select()
        .maybeSingle();

    if (data == null) return null;
    return StudySessionModel.fromJson(data);
  }

  // Record activity (future: chat / emoji / sticker)

  /// Resets the inactivity clock for the current device.
  static Future<void> recordActivity() async {
    final deviceId = await getCurrentDeviceId();
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('study_sessions')
        .update({'last_activity_at': now})
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true);
  }

  // Fetch current device's active session

  static Future<StudySessionModel?> getActiveSessionForUser() async {
    final deviceId = await getCurrentDeviceId();
    final data = await _client
        .from('study_sessions')
        .select()
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true)
        .maybeSingle();

    if (data == null) return null;
    return StudySessionModel.fromJson(data);
  }

  // Fetch visible active sessions in a room

  /// Returns one visible active session per user for room UI purposes.
  ///
  /// Multi-device rows are deduped so the room still renders one seat/member
  /// per user, while the current device keeps its own session identity.
  static Future<List<StudySessionModel>> getActiveSessions(
    String roomId,
  ) async {
    final currentDeviceId = await getCurrentDeviceId();
    final data = await _client
        .from('study_sessions')
        .select()
        .eq('room_id', roomId)
        .eq('is_active', true)
        .order('last_activity_at', ascending: false)
        .order('start_time', ascending: false);

    final sessions = (data as List<dynamic>)
        .map((j) => StudySessionModel.fromJson(j as Map<String, dynamic>))
        .toList();

    final dedupedByUser = <String, StudySessionModel>{};
    for (final session in sessions) {
      final existing = dedupedByUser[session.userId];
      if (existing == null ||
          _shouldPreferRoomSession(session, existing, currentDeviceId)) {
        dedupedByUser[session.userId] = session;
      }
    }

    final visibleSessions = dedupedByUser.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return visibleSessions;
  }

  // Force-close active session (ghost-session prevention)

  /// Force-closes the current device's active session only.
  static Future<void> forceCloseActiveSession() async {
    final deviceId = await getCurrentDeviceId();
    final existing = await _client
        .from('study_sessions')
        .select('last_activity_at')
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true)
        .maybeSingle();

    if (existing == null) return;

    final endTime =
        existing['last_activity_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();

    await _client
        .from('study_sessions')
        .update({'is_active': false, 'end_time': endTime})
        .eq('user_id', _uid)
        .eq('device_id', deviceId)
        .eq('is_active', true);
  }

  // Stale-session cleanup (pg_cron fallback)

  /// Triggers the [close_stale_sessions] DB function client-side.
  static Future<void> cleanUpStaleSessions() async {
    try {
      await _client.rpc('close_stale_sessions');
    } catch (_) {
      // Best-effort - never block app startup.
    }
  }

  static bool _shouldPreferRoomSession(
    StudySessionModel candidate,
    StudySessionModel existing,
    String currentDeviceId,
  ) {
    final candidateIsCurrentDevice =
        candidate.userId == _uid && candidate.deviceId == currentDeviceId;
    final existingIsCurrentDevice =
        existing.userId == _uid && existing.deviceId == currentDeviceId;

    if (candidateIsCurrentDevice != existingIsCurrentDevice) {
      return candidateIsCurrentDevice;
    }

    final candidateActivity = candidate.lastActivityAt ?? candidate.startTime;
    final existingActivity = existing.lastActivityAt ?? existing.startTime;
    if (candidateActivity.isAtSameMomentAs(existingActivity)) {
      return candidate.startTime.isAfter(existing.startTime);
    }
    return candidateActivity.isAfter(existingActivity);
  }
}
