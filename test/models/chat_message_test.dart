import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:studysync/models/chat_message.dart';

void main() {
  group('ChatMessage.fromBroadcast', () {
    test('should parse a valid payload correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0, 0);
      final payload = {
        'message_id': 'msg_123',
        'user_id': 'user_456',
        'username': 'Alice',
        'text': 'Hello world!',
        'ts': now.toIso8601String(),
        'reactions': {
          '👍': ['user_1', 'user_2'],
          '🎉': ['user_3'],
        },
      };

      final message = ChatMessage.fromBroadcast(payload);

      expect(message.messageId, 'msg_123');
      expect(message.userId, 'user_456');
      expect(message.username, 'Alice');
      expect(message.text, 'Hello world!');
      expect(message.timestamp, now);
      expect(message.reactions['👍'], containsAll(['user_1', 'user_2']));
      expect(message.reactions['🎉'], contains('user_3'));
    });

    test('should use default values for missing or null fields', () {
      final fixedNow = DateTime(2024, 1, 1, 12, 0, 0);

      withClock(Clock.fixed(fixedNow), () {
        final payload = <String, dynamic>{};
        final message = ChatMessage.fromBroadcast(payload);

        expect(message.messageId, '');
        expect(message.userId, '');
        expect(message.username, 'Unknown User');
        expect(message.text, '');
        expect(message.timestamp, fixedNow);
        expect(message.reactions, isEmpty);
      });
    });

    test('should handle type mismatches gracefully', () {
      final payload = {
        'message_id': 123, // int instead of string
        'user_id': 456, // int instead of string
        'username': true, // bool instead of string
        'text': {'key': 'value'}, // map instead of string
        'ts': 2024, // int instead of string
        'reactions': 'not-a-map', // string instead of map
      };

      final message = ChatMessage.fromBroadcast(payload);

      expect(message.messageId, '123');
      expect(message.userId, '456');
      expect(message.username, 'true');
      expect(message.text, '{key: value}');
      // Invalid TS should fall back to now
      expect(message.timestamp, isA<DateTime>());
      expect(message.reactions, isEmpty);
    });

    test('should handle extremely long strings', () {
      final giantString = 'A' * 10000;
      final payload = {
        'message_id': giantString,
        'user_id': giantString,
        'username': giantString,
        'text': giantString,
      };

      final message = ChatMessage.fromBroadcast(payload);

      expect(message.messageId, giantString);
      expect(message.userId, giantString);
      expect(message.username, giantString);
      expect(message.text, giantString);
    });

    test('should parse reactions even if malformed', () {
      final payload = {
        'reactions': {
          '👍': 'not-a-list', // should be ignored
          '🎉': [1, 2, 3], // should be converted to strings
          123: ['user_x'], // key should be converted to string
        },
      };

      final message = ChatMessage.fromBroadcast(payload);

      expect(message.reactions.containsKey('👍'), isFalse);
      expect(message.reactions['🎉'], containsAll(['1', '2', '3']));
      expect(message.reactions['123'], contains('user_x'));
    });
  });

  group('ChatMessage.toBroadcastPayload', () {
    test('should convert ChatMessage to a valid map', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final message = ChatMessage(
        messageId: 'msg_123',
        userId: 'user_456',
        username: 'Alice',
        text: 'Hello world!',
        timestamp: timestamp,
        reactions: {
          '👍': {'user_1', 'user_2'},
        },
      );

      final payload = message.toBroadcastPayload();

      expect(payload['message_id'], 'msg_123');
      expect(payload['user_id'], 'user_456');
      expect(payload['username'], 'Alice');
      expect(payload['text'], 'Hello world!');
      expect(payload['ts'], timestamp.toIso8601String());
      expect(payload['reactions'], isA<Map>());
      expect(payload['reactions']['👍'], containsAll(['user_1', 'user_2']));
    });
  });
}
