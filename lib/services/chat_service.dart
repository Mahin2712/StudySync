import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

/// Dual-layer ephemeral chat service using Supabase Realtime Broadcasting.
///
/// Architecture:
///   - Global Chat  → channel: `public:global_chat`  (accessible from HomeScreen)
///   - Room Chat    → channel: `room:chat_{room_id}` (accessible from RoomDetailScreen)
///
/// Messages are NEVER written to the database; they are purely ephemeral
/// Broadcast payloads and support full Unicode / emoji natively.
class ChatService extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────────────────
  // Singleton
  // ─────────────────────────────────────────────────────────────────────────
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // Spam-guard constants
  // ─────────────────────────────────────────────────────────────────────────
  static const int _cooldownSeconds = 3;
  static const int _maxChars = 120;
  static const int _maxStoredMessages = 80; // keep memory bounded

  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────
  RealtimeChannel? _globalChannel;
  RealtimeChannel? _roomChannel;
  String? _currentRoomId;

  final List<ChatMessage> _globalMessages = [];
  final List<ChatMessage> _roomMessages = [];

  // Spam guard state (shared across both channels; one user, one cooldown)
  DateTime? _lastSentAt;
  String? _lastSentText;

  // Cooldown countdown for UI
  int _cooldownRemaining = 0; // seconds left on cooldown
  Timer? _cooldownTimer;

  // ─────────────────────────────────────────────────────────────────────────
  // Read-only accessors
  // ─────────────────────────────────────────────────────────────────────────
  List<ChatMessage> get globalMessages => List.unmodifiable(_globalMessages);
  List<ChatMessage> get roomMessages => List.unmodifiable(_roomMessages);

  /// Seconds remaining before the user can send another message.
  int get cooldownRemaining => _cooldownRemaining;
  bool get isOnCooldown => _cooldownRemaining > 0;

  String? get currentRoomId => _currentRoomId;

  // ─────────────────────────────────────────────────────────────────────────
  // Current user helpers
  // ─────────────────────────────────────────────────────────────────────────
  String get _myUserId => _supabase.auth.currentUser?.id ?? '';

  String get _myUsername {
    final email = _supabase.auth.currentUser?.email ?? '';
    // Use the part before @ as the display name
    return email.split('@').first.isNotEmpty ? email.split('@').first : 'Student';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Global Chat
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to the global broadcast channel.
  /// Call once from [HomeScreen.initState].
  Future<void> joinGlobalChat() async {
    if (_globalChannel != null) return; // already subscribed

    _globalChannel = _supabase
        .channel('public:global_chat')
        .onBroadcast(
          event: 'message',
          callback: (payload) => _onIncomingMessage(payload, isGlobal: true),
        )
        .subscribe();
  }

  /// Unsubscribes from the global channel.
  /// Call from [HomeScreen.dispose].
  Future<void> leaveGlobalChat() async {
    if (_globalChannel == null) return;
    await _supabase.removeChannel(_globalChannel!);
    _globalChannel = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Room Chat
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to the room-specific broadcast channel.
  /// Call from [RoomDetailScreen.initState] with the current room's ID.
  Future<void> joinRoomChat(String roomId) async {
    // Leave any existing room channel first
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await leaveRoomChat();
    }

    if (_currentRoomId == roomId && _roomChannel != null) return;

    _currentRoomId = roomId;
    _roomMessages.clear();

    _roomChannel = _supabase
        .channel('room:chat_$roomId')
        .onBroadcast(
          event: 'message',
          callback: (payload) => _onIncomingMessage(payload, isGlobal: false),
        )
        .subscribe();
  }

  /// Unsubscribes from the current room channel.
  /// Call from [RoomDetailScreen.dispose].
  Future<void> leaveRoomChat() async {
    if (_roomChannel == null) return;
    await _supabase.removeChannel(_roomChannel!);
    _roomChannel = null;
    _currentRoomId = null;
    _roomMessages.clear();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Send a Message
  // ─────────────────────────────────────────────────────────────────────────

  /// Attempts to send a message on either the global or room channel.
  ///
  /// Returns a [ChatSendResult] describing success or the reason for failure.
  ChatSendResult sendMessage(String rawText, {required bool isGlobal}) {
    // ── 1. Trim whitespace ──────────────────────────────────────────────
    final text = rawText.trim();

    // ── 2. Empty check ──────────────────────────────────────────────────
    if (text.isEmpty) return ChatSendResult.empty;

    // ── 3. Character limit ──────────────────────────────────────────────
    if (text.length > _maxChars) return ChatSendResult.tooLong;

    // ── 4. Cooldown check ───────────────────────────────────────────────
    if (isOnCooldown) return ChatSendResult.onCooldown;
    if (_lastSentAt != null) {
      final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
      if (elapsed < _cooldownSeconds) {
        _startCooldown(_cooldownSeconds - elapsed);
        return ChatSendResult.onCooldown;
      }
    }

    // ── 5. Duplicate block ──────────────────────────────────────────────
    if (text == _lastSentText) return ChatSendResult.duplicate;

    // ── 6. Channel availability ─────────────────────────────────────────
    final channel = isGlobal ? _globalChannel : _roomChannel;
    if (channel == null) return ChatSendResult.notConnected;

    // ── 7. Build and broadcast ──────────────────────────────────────────
    final message = ChatMessage(
      userId: _myUserId,
      username: _myUsername,
      text: text,
      timestamp: DateTime.now(),
    );

    channel.sendBroadcastMessage(
      event: 'message',
      payload: message.toBroadcastPayload(),
    );

    // ── 8. Update spam guard state ──────────────────────────────────────
    _lastSentAt = DateTime.now();
    _lastSentText = text;
    _startCooldown(_cooldownSeconds);

    return ChatSendResult.success;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _onIncomingMessage(Map<String, dynamic> payload, {required bool isGlobal}) {
    final msg = ChatMessage.fromBroadcast(payload);
    if (isGlobal) {
      _globalMessages.add(msg);
      if (_globalMessages.length > _maxStoredMessages) {
        _globalMessages.removeAt(0);
      }
    } else {
      _roomMessages.add(msg);
      if (_roomMessages.length > _maxStoredMessages) {
        _roomMessages.removeAt(0);
      }
    }
    notifyListeners();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    _cooldownRemaining = seconds;
    notifyListeners();

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldownRemaining <= 0) {
        t.cancel();
        _cooldownRemaining = 0;
      } else {
        _cooldownRemaining--;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    leaveGlobalChat();
    leaveRoomChat();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result enum for send operations
// ─────────────────────────────────────────────────────────────────────────────

enum ChatSendResult {
  success,
  empty,
  tooLong,
  onCooldown,
  duplicate,
  notConnected;

  String get userMessage => switch (this) {
        ChatSendResult.success => '',
        ChatSendResult.empty => 'Message cannot be empty.',
        ChatSendResult.tooLong => 'Max 120 characters allowed.',
        ChatSendResult.onCooldown => 'Please wait before sending again.',
        ChatSendResult.duplicate => 'You already sent that message.',
        ChatSendResult.notConnected => 'Chat not connected. Please wait.',
      };
}
