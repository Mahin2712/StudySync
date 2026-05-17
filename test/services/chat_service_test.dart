import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studysync/services/chat_service.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
class MockUser extends Mock implements User {}

void main() {
  late ChatService chatService;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockRealtimeChannel mockChannel;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(const AuthState(AuthChangeEvent.signedOut, null));
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockChannel = MockRealtimeChannel();
    mockUser = MockUser();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockAuth.onAuthStateChange).thenAnswer(
      (_) => Stream.fromIterable([const AuthState(AuthChangeEvent.signedIn, null)]),
    );

    // Mock RealtimeChannel methods
    when(() => mockChannel.onBroadcast(
          event: any(named: 'event'),
          callback: any(named: 'callback'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe()).thenReturn(mockChannel);

    // For joining chat
    when(() => mockSupabase.channel(any())).thenReturn(mockChannel);

    chatService = ChatService.forTesting(supabaseClient: mockSupabase);
  });

  group('ChatService sendMessage', () {
    test('should return success when message is sent successfully', () async {
      await chatService.joinGlobalChat();

      when(() => mockChannel.sendBroadcastMessage(
            event: any(named: 'event'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => ChannelResponse.ok);

      final result = await chatService.sendMessage('Hello', isGlobal: true);

      expect(result, ChatSendResult.success);
      expect(chatService.globalMessages.length, 1);
      expect(chatService.globalMessages.first.text, 'Hello');
    });

    test('should return sendFailed and rollback on transport failure', () async {
      await chatService.joinGlobalChat();

      when(() => mockChannel.sendBroadcastMessage(
            event: any(named: 'event'),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('Network error'));

      final result = await chatService.sendMessage('Hello', isGlobal: true);

      expect(result, ChatSendResult.sendFailed);
      expect(chatService.globalMessages.isEmpty, true);
    });

    test('should return rateLimited and rollback on 429 error', () async {
      await chatService.joinGlobalChat();

      when(() => mockChannel.sendBroadcastMessage(
            event: any(named: 'event'),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('429: Too Many Requests'));

      final result = await chatService.sendMessage('Hello', isGlobal: true);

      expect(result, ChatSendResult.rateLimited);
      expect(chatService.globalMessages.isEmpty, true);
    });
  });

  group('ChatService sendReaction', () {
    test('should return true on success', () async {
      await chatService.joinGlobalChat();

      // Add a message first
      when(() => mockChannel.sendBroadcastMessage(
            event: 'message',
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => ChannelResponse.ok);
      await chatService.sendMessage('Hello', isGlobal: true);
      final msgId = chatService.globalMessages.first.messageId;

      when(() => mockChannel.sendBroadcastMessage(
            event: 'reaction',
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => ChannelResponse.ok);

      final result = await chatService.sendReaction(msgId, '👍', isGlobal: true);

      expect(result, true);
      expect(chatService.globalMessages.first.reactions['👍']!.contains('test-user-id'), true);
    });

    test('should return false and rollback on failure', () async {
      await chatService.joinGlobalChat();

      // Add a message first
      when(() => mockChannel.sendBroadcastMessage(
            event: 'message',
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => ChannelResponse.ok);
      await chatService.sendMessage('Hello', isGlobal: true);
      final msgId = chatService.globalMessages.first.messageId;

      when(() => mockChannel.sendBroadcastMessage(
            event: 'reaction',
            payload: any(named: 'payload'),
          )).thenThrow(Exception('Error'));

      final result = await chatService.sendReaction(msgId, '👍', isGlobal: true);

      expect(result, false);
      // Reaction should be toggled back to empty
      expect(chatService.globalMessages.first.reactions['👍'], null);
    });
  });

  group('ChatService input validation', () {
    test('should return empty when text is empty', () async {
      final result = await chatService.sendMessage('', isGlobal: true);
      expect(result, ChatSendResult.empty);
    });

    test('should return tooLong when text exceeds limit', () async {
      final longText = 'a' * 121;
      final result = await chatService.sendMessage(longText, isGlobal: true);
      expect(result, ChatSendResult.tooLong);
    });
  });
}
