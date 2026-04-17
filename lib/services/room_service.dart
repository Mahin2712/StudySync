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
  static Future<String> createRoom(String name, {String subject = 'Others'}) async {
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

  /// Join a room (insert into room_members — note Supabase typo)
  ///
  /// Force-closes any active study session before joining to prevent
  /// "ghost studier" rows when the user hops between rooms.
  static Future<void> joinRoom(String roomId) async {
    final userId = _client.auth.currentUser!.id;

    // 1. Kill any active session (ghost-session prevention).
    await SessionService.forceCloseActiveSession();

    // 2. Prevent duplicate room_member entries.
    final existing = await _client
        .from('room_members')
        .select('id')
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('room_members').insert({
        'room_id': roomId,
        'user_id': userId,
      });
    }
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

    return (data as List)
        .map((m) => m['user_id'] as String)
        .toList();
  }
}
