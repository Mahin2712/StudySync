import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  // ─── Fetch ────────────────────────────────────────────────────────────────

  /// Fetch the current logged-in user's profile.
  static Future<ProfileModel?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getProfileById(uid);
  }

  /// Fetch any user's profile by their UUID.
  static Future<ProfileModel?> getProfileById(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  /// Search profiles by username or student_name (case-insensitive partial match).
  static Future<List<ProfileModel>> searchProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _client
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,student_name.ilike.%$query%')
        .limit(20);
    return data.map((j) => ProfileModel.fromJson(j)).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  /// Save (upsert) profile fields for the current user.
  /// Marks profile_complete = true when all required fields are present.
  static Future<void> saveProfile({
    required String username,
    required String studentName,
    required String schoolName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final isComplete = username.isNotEmpty &&
        studentName.isNotEmpty &&
        schoolName.isNotEmpty;

    await _client.from('profiles').upsert({
      'id': uid,
      'username': username.trim(),
      'student_name': studentName.trim(),
      'school_name': schoolName.trim(),
      'phone_number': phoneNumber?.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'profile_complete': isComplete,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ─── Guard ────────────────────────────────────────────────────────────────

  /// Returns true if current user has a complete profile.
  /// Used by the navigation guard to redirect to ProfileSetupScreen.
  static Future<bool> isProfileComplete() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final data = await _client
        .from('profiles')
        .select('profile_complete')
        .eq('id', uid)
        .maybeSingle();
    return (data?['profile_complete'] as bool?) ?? false;
  }
}
