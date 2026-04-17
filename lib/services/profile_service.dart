import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  // ─── Fetch ────────────────────────────────────────────────────────────────

  /// Fetch the current logged-in user's FULL profile (includes private fields).
  /// Only use for the logged-in user's own data.
  static Future<ProfileModel?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  /// Fetch another user's PUBLIC profile by UUID.
  ///
  /// Queries the [public_profiles] view — phone_number and email are
  /// never exposed. For the current user's own data, use [getMyProfile].
  static Future<ProfileModel?> getProfileById(String userId) async {
    final myUid = _client.auth.currentUser?.id;
    // If fetching own profile, use full profiles table.
    final table = (userId == myUid) ? 'profiles' : 'public_profiles';
    final data = await _client
        .from(table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  /// Search other users' profiles via the privacy-safe [public_profiles] view.
  ///
  /// Never returns phone_number or email — only public fields.
  static Future<List<ProfileModel>> searchPublicProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _client
        .from('public_profiles')
        .select()
        .or('username.ilike.%$query%,student_name.ilike.%$query%')
        .limit(20);
    return data.map((j) => ProfileModel.fromJson(j)).toList();
  }

  /// @deprecated Use [searchPublicProfiles] instead.
  static Future<List<ProfileModel>> searchProfiles(String query) =>
      searchPublicProfiles(query);

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
      'avatar_url': avatarUrl,
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
