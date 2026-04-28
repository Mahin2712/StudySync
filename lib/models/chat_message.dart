/// Immutable model for an ephemeral Broadcast chat message.
/// Messages are never persisted to the database.
class ChatMessage {
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  /// Parses a raw Broadcast payload map into a [ChatMessage].
  factory ChatMessage.fromBroadcast(Map<String, dynamic> payload) {
    return ChatMessage(
      userId: (payload['user_id'] as String?) ?? '',
      username: (payload['username'] as String?) ?? 'Anonymous',
      text: (payload['text'] as String?) ?? '',
      timestamp: DateTime.tryParse(
            (payload['ts'] as String?) ?? '',
          ) ??
          DateTime.now(),
    );
  }

  /// Converts this message into a Broadcast payload map.
  Map<String, dynamic> toBroadcastPayload() => {
        'user_id': userId,
        'username': username,
        'text': text,
        'ts': timestamp.toIso8601String(),
      };
}
