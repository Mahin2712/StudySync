class RoomModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  int memberCount;

  RoomModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Room',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
