class SubjectModel {
  final String key;
  final String displayName;
  final String emoji;
  final int sortOrder;
  final String category;

  const SubjectModel({
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.sortOrder,
    this.category = 'Other',
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      key: json['key'] as String,
      displayName: json['display_name'] as String,
      emoji: json['emoji'] as String? ?? '📚',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'Other',
    );
  }
}
