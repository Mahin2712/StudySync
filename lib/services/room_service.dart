import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';
import 'session_service.dart';

class RoomService {
  static final _client = Supabase.instance.client;

  /// Fetch all rooms (with active studier counts)
  static Future<List<RoomModel>> fetchRooms() async {
    final data = await _client
        .from('room_member_counts')
        .select('*')
        .order('created_at', ascending: false);

    final rooms = (data as List).map((json) {
      final room = RoomModel.fromJson(json as Map<String, dynamic>);
      room.memberCount = (json['active_studiers'] as num?)?.toInt() ?? 0;
      return room;
    }).toList();

    return rooms;
  }

  /// Create a new room and return its id
  static Future<String> createRoom(
    String name, {
    String subject = 'Others',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('rooms')
        .insert({
          'name': name,
          'created_by': userId,
          'subject': subject,
          'is_custom': true,
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Join a room (upsert into room_members).
  ///
  /// Joins the given room for the current user.
  ///
  /// The membership upsert is performed first. The active study session is only
  /// force-closed after the join is confirmed, so a failed join (network error,
  /// RLS rejection, etc.) leaves the user's current session intact.
  ///
  /// H2 fix: reversed the previous order (close → join) which could permanently
  /// destroy the active session when the join failed.
  static Future<void> joinRoom(String roomId) async {
    final userId = _client.auth.currentUser!.id;

    // 1. Idempotent upsert — succeeds whether the membership row already
    //    exists or not. onConflict targets the unique index on (room_id, user_id).
    //    Throws on any backend error; session is still active at this point.
    await _client.from('room_members').upsert(
      {
        'room_id': roomId,
        'user_id': userId,
      },
      onConflict: 'room_id,user_id',
      ignoreDuplicates: true,
    );

    // 2. Join confirmed — now safe to close the previous session.
    //    Ghost-studier rows from the old room are cleaned up here.
    await SessionService.forceCloseActiveSession();
  }

  /// Leave a room
  static Future<void> leaveRoom(String roomId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  /// Get members of a specific room
  static Future<List<String>> getRoomMembers(String roomId) async {
    final data = await _client
        .from('room_members')
        .select('user_id')
        .eq('room_id', roomId);

    return (data as List).map((m) => m['user_id'] as String).toList();
  }
}
