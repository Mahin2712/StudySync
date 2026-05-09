import 'package:flutter_test/flutter_test.dart';
import 'package:studysync/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final now = DateTime.now().toUtc();

    test('toBroadcastPayload should include all fields including reactions', () {
      final message = ChatMessage(
        messageId: 'msg-123',
        userId: 'user-456',
        username: 'testuser',
        text: 'hello world',
        timestamp: now,
        reactions: {
          '👍': {'user-1', 'user-2'},
          '❤️': {'user-3'},
        },
      );

      final payload = message.toBroadcastPayload();

      expect(payload['message_id'], 'msg-123');
      expect(payload['user_id'], 'user-456');
      expect(payload['username'], 'testuser');
      expect(payload['text'], 'hello world');
      expect(payload['ts'], now.toIso8601String());
      expect(payload['reactions'], {
        '👍': containsAll(['user-1', 'user-2']),
        '❤️': containsAll(['user-3']),
      });
      expect((payload['reactions'] as Map)['👍'], hasLength(2));
    });

    test('fromBroadcast should parse all fields correctly', () {
      final payload = {
        'message_id': 'msg-123',
        'user_id': 'user-456',
        'username': 'testuser',
        'text': 'hello world',
        'ts': now.toIso8601String(),
        'reactions': {
          '👍': ['user-1', 'user-2'],
        },
      };

      final message = ChatMessage.fromBroadcast(payload);

      expect(message.messageId, 'msg-123');
      expect(message.userId, 'user-456');
      expect(message.username, 'testuser');
      expect(message.text, 'hello world');
      expect(message.timestamp.toIso8601String(), now.toIso8601String());
      expect(message.reactions['👍'], containsAll(['user-1', 'user-2']));
    });

    test('Serialization/Deserialization cycle should preserve data', () {
      final original = ChatMessage(
        messageId: 'cycle-1',
        userId: 'user-1',
        username: 'user1',
        text: 'test cycle',
        timestamp: now,
        reactions: {
          '🚀': {'u1', 'u2'},
        },
      );

      final payload = original.toBroadcastPayload();
      final recovered = ChatMessage.fromBroadcast(payload);

      expect(recovered.messageId, original.messageId);
      expect(recovered.userId, original.userId);
      expect(recovered.username, original.username);
      expect(recovered.text, original.text);
      expect(recovered.timestamp.toIso8601String(), original.timestamp.toIso8601String());
      expect(recovered.reactions['🚀'], original.reactions['🚀']);
    });

    group('Edge Cases', () {
      test('Type safety: handles non-string types in payload', () {
        final payload = {
          'message_id': 123,
          'user_id': 456,
          'username': true,
          'text': 78.9,
          'ts': '2023-01-01T12:00:00Z',
          'reactions': {
            'emoji': [1, 2, 3],
          },
        };

        final message = ChatMessage.fromBroadcast(payload);

        expect(message.messageId, '123');
        expect(message.userId, '456');
        expect(message.username, 'true');
        expect(message.text, '78.9');
        expect(message.reactions['emoji'], containsAll(['1', '2', '3']));
      });

      test('Spam/Length: handles extremely long strings', () {
        final longText = 'A' * 10000;
        final message = ChatMessage(
          messageId: 'id',
          userId: 'uid',
          username: 'name',
          text: longText,
          timestamp: now,
        );

        final payload = message.toBroadcastPayload();
        expect(payload['text'], longText);

        final recovered = ChatMessage.fromBroadcast(payload);
        expect(recovered.text, longText);
      });

      test('Missing fields: provides default values', () {
        final payload = <String, dynamic>{};
        final message = ChatMessage.fromBroadcast(payload);

        expect(message.messageId, '');
        expect(message.userId, '');
        expect(message.username, 'Unknown User');
        expect(message.text, '');
        expect(message.reactions, isEmpty);
        // timestamp should be close to now
        expect(
          DateTime.now().difference(message.timestamp).inSeconds,
          lessThan(2),
        );
      });

      test('Invalid timestamp: provides fallback to now', () {
        final payload = {'ts': 'not-a-date'};
        final message = ChatMessage.fromBroadcast(payload);

        expect(
          DateTime.now().difference(message.timestamp).inSeconds,
          lessThan(2),
        );
      });
    });
  });
}
