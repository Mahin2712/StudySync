/// A single to-do item.
class TodoModel {
  final String id;
  final String userId;
  final String title;
  final bool isDone;
  final bool isRecurring;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.isDone = false,
    this.isRecurring = false,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      isDone: (json['is_done'] as bool?) ?? false,
      isRecurring: (json['is_recurring'] as bool?) ?? false,
      position: (json['position'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'is_recurring': isRecurring,
      'position': position,
      'user_id': userId,
    };
  }

  TodoModel copyWith({
    bool? isDone,
    String? title,
    int? position,
  }) {
    return TodoModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      isRecurring: isRecurring,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
