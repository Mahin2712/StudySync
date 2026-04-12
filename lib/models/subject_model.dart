class SubjectModel {
  final String key;
  final String displayName;
  final String emoji;
  final int sortOrder;

  const SubjectModel({
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.sortOrder,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      key: json['key'] as String,
      displayName: json['display_name'] as String,
      emoji: json['emoji'] as String? ?? '📚',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
