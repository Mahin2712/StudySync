import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_model.dart';

class SubjectService {
  static final _client = Supabase.instance.client;
  static List<SubjectModel>? _cachedSubjects;

  static const List<SubjectModel> _fallbackSubjects = [
    SubjectModel(key: 'physics', displayName: 'Physics', emoji: '⚛️', sortOrder: 1),
    SubjectModel(key: 'chemistry', displayName: 'Chemistry', emoji: '🧪', sortOrder: 2),
    SubjectModel(key: 'biology', displayName: 'Biology', emoji: '🧬', sortOrder: 3),
    SubjectModel(key: 'general math', displayName: 'General Math', emoji: '🔢', sortOrder: 4),
    SubjectModel(key: 'higher math', displayName: 'Higher Math', emoji: '📐', sortOrder: 5),
    SubjectModel(key: 'bangla 1st', displayName: 'Bangla 1st', emoji: '📖', sortOrder: 6),
    SubjectModel(key: 'bangla 2nd', displayName: 'Bangla 2nd', emoji: '📝', sortOrder: 7),
    SubjectModel(key: 'english 1st', displayName: 'English 1st', emoji: '🔠', sortOrder: 8),
    SubjectModel(key: 'english 2nd', displayName: 'English 2nd', emoji: '✒️', sortOrder: 9),
    SubjectModel(key: 'history', displayName: 'History', emoji: '📜', sortOrder: 10),
    SubjectModel(key: 'ict', displayName: 'ICT', emoji: '💻', sortOrder: 11),
    SubjectModel(key: 'islam', displayName: 'Islam', emoji: '🌙', sortOrder: 12),
    SubjectModel(key: 'hinduism', displayName: 'Hinduism', emoji: '🕉️', sortOrder: 13),
  ];

  /// Fetch subjects from DB, or return cached/fallback if offline.
  static Future<List<SubjectModel>> getSubjects() async {
    if (_cachedSubjects != null) return _cachedSubjects!;
    try {
      final data = await _client
          .from('subjects')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      _cachedSubjects = (data as List)
          .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedSubjects!;
    } catch (e) {
      // Fallback to hardcoded if DB fetch fails (e.g., offline)
      return _fallbackSubjects;
    }
  }

  /// Get subjects synchronously. Assumes getSubjects() has been called at least once
  /// (e.g., during app load or dashboard init), otherwise returns fallback immediately.
  static List<SubjectModel> getCachedSubjects() {
    return _cachedSubjects ?? _fallbackSubjects;
  }

  /// Check if a subject key is a standard subject.
  static Future<bool> isStandardSubject(String key) async {
    final subjects = await getSubjects();
    return subjects.any((s) => s.key == key);
  }
}
