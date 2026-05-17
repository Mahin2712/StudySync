import 'package:clock/clock.dart';

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
    // Safely parse reactions
    final Map<String, Set<String>> parsedReactions = {};
    final rawReactions = payload['reactions'];
    if (rawReactions is Map) {
      rawReactions.forEach((key, value) {
        if (value is List) {
          parsedReactions[key.toString()] = value
              .map((e) => e.toString())
              .toSet();
        }
      });
    }

    return ChatMessage(
      messageId: payload['message_id']?.toString() ?? '',
      userId: payload['user_id']?.toString() ?? '',
      username: payload['username']?.toString() ?? 'Unknown User',
      text: payload['text']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(payload['ts']?.toString() ?? '') ?? clock.now(),
      reactions: parsedReactions,
    );
  }

  /// Converts this message into a Broadcast payload map.
  Map<String, dynamic> toBroadcastPayload() => {
    'message_id': messageId,
    'user_id': userId,
    'username': username,
    'text': text,
    'ts': timestamp.toIso8601String(),
    'reactions': reactions.map((key, value) => MapEntry(key, value.toList())),
  };
}
