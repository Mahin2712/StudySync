import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

class RoomService {
  static final _client = Supabase.instance.client;

  /// Fetch all rooms (with member counts)
  static Future<List<RoomModel>> fetchRooms() async {
    final data = await _client
        .from('rooms')
        .select('*')
        .order('created_at', ascending: false);

    final rooms = (data as List)
        .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Fetch member counts for all rooms
    final members = await _client.from('room_members').select('room_id');

    final countMap = <String, int>{};
    for (final m in members as List) {
      final rid = m['room_id'] as String;
      countMap[rid] = (countMap[rid] ?? 0) + 1;
    }

    for (final room in rooms) {
      room.memberCount = countMap[room.id] ?? 0;
    }

    return rooms;
  }

  /// Create a new room and return its id
  static Future<String> createRoom(String name) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('rooms')
        .insert({'name': name, 'created_by': userId})
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Join a room (insert into room_members — note Supabase typo)
  static Future<void> joinRoom(String roomId) async {
    final userId = _client.auth.currentUser!.id;

    // Prevent duplicate entries
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
