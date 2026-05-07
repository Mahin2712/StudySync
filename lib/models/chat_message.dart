/// Model for an ephemeral Broadcast chat message.
/// Messages are never persisted to the database.
class ChatMessage {
  final String messageId;
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;

  // Mutable map of emoji -> Set of userIds who reacted
  final Map<String, Set<String>> reactions;

  ChatMessage({
    required this.messageId,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
    Map<String, Set<String>>? reactions,
  }) : reactions = reactions ?? {};

  /// Parses a raw Broadcast payload map into a [ChatMessage].
  factory ChatMessage.fromBroadcast(Map<String, dynamic> payload) {
    return ChatMessage(
      messageId: (payload['message_id'] as String?) ?? '',
      userId: (payload['user_id'] as String?) ?? '',
      username: (payload['username'] as String?) ?? 'Anonymous',
      text: (payload['text'] as String?) ?? '',
      timestamp: DateTime.tryParse(
            (payload['ts'] as String?) ?? '',
          ) ??
          DateTime.now(),
      reactions: {},
    );
  }

  /// Converts this message into a Broadcast payload map.
  Map<String, dynamic> toBroadcastPayload() => {
        'message_id': messageId,
        'user_id': userId,
        'username': username,
        'text': text,
        'ts': timestamp.toIso8601String(),
      };
}
