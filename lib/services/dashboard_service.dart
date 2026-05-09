import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry_model.dart';
import '../models/room_model.dart';

class DashboardData {
  final int globalCount;
  final List<RoomModel> trendingRooms;
  final List<LeaderboardEntry> leaderboard;
  final List<RoomModel> recentRooms;

  const DashboardData({
    this.globalCount = 0,
    this.trendingRooms = const [],
    this.leaderboard = const [],
    this.recentRooms = const [],
  });
}

class DashboardService {
  static final _client = Supabase.instance.client;

  /// Fetch all dashboard data in parallel for fast initialization.
  static Future<DashboardData> getDashboardData() async {
    try {
      final results = await Future.wait([
        _getGlobalActiveCount(),
        _getTrendingRooms(),
        _getTopLeaderboard(),
        _getRecentRooms(),
      ]);

      return DashboardData(
        globalCount: results[0] as int,
        trendingRooms: results[1] as List<RoomModel>,
        leaderboard: results[2] as List<LeaderboardEntry>,
        recentRooms: results[3] as List<RoomModel>,
      );
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  static Future<int> _getGlobalActiveCount() async {
    try {
      final count = await _client
          .from('study_sessions')
          .count(CountOption.exact)
          .eq('is_active', true);
      return count;
    } catch (_) {
      return 0; // Return 0 gracefully if fails
    }
  }

  static Future<List<RoomModel>> _getTrendingRooms({int limit = 5}) async {
    try {
      final data = await _client
          .from('room_member_counts')
          .select('*')
          .order('active_studiers', ascending: false)
          .limit(limit);

      return (data as List).map((json) {
        final room = RoomModel.fromJson(json as Map<String, dynamic>);
        room.memberCount = (json['active_studiers'] as num?)?.toInt() ?? 0;
        return room;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<LeaderboardEntry>> _getTopLeaderboard({
    int limit = 3,
  }) async {
    try {
      final data =
          await _client.from('leaderboard_all_time').select().limit(limit);

      return (data as List)
          .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<RoomModel>> _getRecentRooms({int limit = 3}) async {
    try {
      final data = await _client.rpc(
        'get_recent_rooms',
        params: {'limit_val': limit},
      );

      return (data as List).map((json) {
        return RoomModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
