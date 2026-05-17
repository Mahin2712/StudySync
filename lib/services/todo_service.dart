import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/todo_model.dart';

/// CRUD service for the user's to-do list.
class TodoService {
  static final _client = Supabase.instance.client;

  static String get _uid => _client.auth.currentUser!.id;

  /// Fetch all todos (sorted by position).
  /// Lazily resets recurring todos for the new day.
  static Future<List<TodoModel>> getTodos() async {
    try {
      // Reset daily recurring items first
      await _client.rpc('reset_recurring_todos');
    } catch (e) {
      debugPrint('[TodoService] reset_recurring_todos failed: $e');
    }

    final data = await _client
        .from('todos')
        .select()
        .eq('user_id', _uid)
        .order('position', ascending: true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => TodoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Add a new to-do.
  static Future<TodoModel> addTodo({
    required String title,
    bool isRecurring = false,
  }) async {
    // Get next position
    final existing = await _client
        .from('todos')
        .select('position')
        .eq('user_id', _uid)
        .order('position', ascending: false)
        .limit(1);

    final nextPos = existing.isNotEmpty
        ? ((existing[0]['position'] as num?)?.toInt() ?? 0) + 1
        : 0;

    final data = await _client
        .from('todos')
        .insert({
          'user_id': _uid,
          'title': title,
          'is_recurring': isRecurring,
          'position': nextPos,
        })
        .select()
        .single();

    return TodoModel.fromJson(data);
  }

  /// Toggle done/undone.
  static Future<void> toggleTodo(String todoId, bool isDone) async {
    await _client
        .from('todos')
        .update({
          'is_done': isDone,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', todoId);
  }

  /// Update the title of a to-do.
  static Future<void> updateTitle(String todoId, String newTitle) async {
    await _client
        .from('todos')
        .update({
          'title': newTitle,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', todoId);
  }

  /// Delete a to-do.
  static Future<void> deleteTodo(String todoId) async {
    await _client.from('todos').delete().eq('id', todoId);
  }
}
