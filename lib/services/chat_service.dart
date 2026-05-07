import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import 'profile_service.dart';

/// Dual-layer ephemeral chat service using Supabase Realtime Broadcasting.
///
/// Architecture:
///   - Global Chat  → channel: `public:global_chat`  (accessible from HomeScreen)
///   - Room Chat    → channel: `room:chat_{room_id}` (accessible from RoomDetailScreen)
///
/// Messages are NEVER written to the database; they are purely ephemeral
/// Broadcast payloads and support full Unicode / emoji natively.
class ChatService extends ChangeNotifier {
  // ════════════════════════════════════════════════════════════════════════
  // Singleton
  // ════════════════════════════════════════════════════════════════════════
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal() {
    // Fix #6: Subscribe to auth changes to reset cached identity on
    // sign-out / sign-in so a different account always gets a fresh username.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated) {
        _resetUserIdentity();
      }
    });
  }

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Fix #6: Hold the auth subscription so we can cancel it in dispose().
  StreamSubscription<AuthState>? _authSubscription;

  // ════════════════════════════════════════════════════════════════════════
  // Spam-guard constants
  // ════════════════════════════════════════════════════════════════════════
  static const int _cooldownSeconds = 3;
  static const int _maxChars = 120;
  static const int _maxStoredMessages = 80; // keep memory bounded

  // ════════════════════════════════════════════════════════════════════════
  // State
  // ════════════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════════════
  // Read-only accessors
  // ════════════════════════════════════════════════════════════════════════
  List<ChatMessage> get globalMessages => List.unmodifiable(_globalMessages);
  List<ChatMessage> get roomMessages => List.unmodifiable(_roomMessages);

  /// Seconds remaining before the user can send another message.
  int get cooldownRemaining => _cooldownRemaining;
  bool get isOnCooldown => _cooldownRemaining > 0;

  String? get currentRoomId => _currentRoomId;

  // ════════════════════════════════════════════════════════════════════════
  // Current user helpers
  // ════════════════════════════════════════════════════════════════════════
  String get _myUserId => _supabase.auth.currentUser?.id ?? '';

  String _cachedUsername = 'Student';
  bool _isUsernameLoaded = false;

  /// Fix #6: Clears the cached identity so the next join call re-fetches
  /// the correct profile for the currently signed-in account.
  void _resetUserIdentity() {
    _isUsernameLoaded = false;
    _cachedUsername = 'Student';
  }

  Future<void> _ensureUsernameLoaded() async {
    if (_isUsernameLoaded) return;
    try {
      final profile = await ProfileService.getMyProfile();
      if (profile != null && profile.username.isNotEmpty) {
        _cachedUsername = profile.username;
      } else {
        final email = _supabase.auth.currentUser?.email ?? '';
        _cachedUsername =
            email.split('@').first.isNotEmpty ? email.split('@').first : 'Student';
      }
      _isUsernameLoaded = true;
    } catch (_) {}
  }

  String get _myUsername => _cachedUsername;

  String _generateMessageId() {
    final prefix = _myUserId.length >= 6 ? _myUserId.substring(0, 6) : _myUserId;
    return '${prefix}_${_uuid.v4()}';
  }

  // ════════════════════════════════════════════════════════════════════════
  // Global Chat
  // ════════════════════════════════════════════════════════════════════════

  /// Subscribes to the global broadcast channel.
  /// Call once from [HomeScreen.initState].
  Future<void> joinGlobalChat() async {
    await _ensureUsernameLoaded();
    if (_globalChannel != null) return; // already subscribed

    _globalChannel = _supabase
        .channel('public:global_chat')
        .onBroadcast(
          event: 'message',
          callback: (payload) => _onIncomingMessage(payload, isGlobal: true),
        )
        .onBroadcast(
          event: 'reaction',
          callback: (payload) => _onIncomingReaction(payload, isGlobal: true),
        )
        .subscribe();
  }

  /// Unsubscribes from the global channel.
  /// Call from [HomeScreen.dispose].
  Future<void> leaveGlobalChat() async {
    if (_globalChannel == null) return;
    await _supabase.removeChannel(_globalChannel!);
    _globalChannel = null;
    _globalMessages.clear();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Room Chat
  // ════════════════════════════════════════════════════════════════════════

  /// Subscribes to a room-scoped broadcast channel.
  /// Call from [RoomDetailScreen.initState].
  Future<void> joinRoomChat(String roomId) async {
    await _ensureUsernameLoaded();

    // Leave old room channel if switching rooms.
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await leaveRoomChat();
    }

    if (_roomChannel != null) return; // already subscribed to this room

    _currentRoomId = roomId;
    _roomChannel = _supabase
        .channel('room:chat_$roomId')
        .onBroadcast(
          event: 'message',
          callback: (payload) => _onIncomingMessage(payload, isGlobal: false),
        )
        .onBroadcast(
          event: 'reaction',
          callback: (payload) => _onIncomingReaction(payload, isGlobal: false),
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

  // ════════════════════════════════════════════════════════════════════════
  // Send a Message
  // ════════════════════════════════════════════════════════════════════════

  /// Attempts to send a message on either the global or room channel.
  ///
  /// Returns a [ChatSendResult] describing success or the reason for failure.
  ///
  /// Fix #4: This is now async so we can await the broadcast and detect
  /// transport-level failures, rolling back the optimistic append if needed.
  Future<ChatSendResult> sendMessage(String rawText, {required bool isGlobal}) async {
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

    // ── 7. Build and optimistically append ──────────────────────────────
    final message = ChatMessage(
      messageId: _generateMessageId(),
      userId: _myUserId,
      username: _myUsername,
      text: text,
      timestamp: DateTime.now(),
    );

    if (isGlobal) {
      _globalMessages.add(message);
      if (_globalMessages.length > _maxStoredMessages) {
        _globalMessages.removeAt(0);
      }
    } else {
      _roomMessages.add(message);
      if (_roomMessages.length > _maxStoredMessages) {
        _roomMessages.removeAt(0);
      }
    }
    notifyListeners();

    // ── 8. Broadcast and handle transport failure ────────────────────────
    // Fix #4: Await the Future<ChannelResponse> so transport errors are caught.
    try {
      await channel.sendBroadcastMessage(
        event: 'message',
        payload: message.toBroadcastPayload(),
      );
    } catch (_) {
      // Roll back the optimistic append on transport failure.
      if (isGlobal) {
        _globalMessages.remove(message);
      } else {
        _roomMessages.remove(message);
      }
      notifyListeners();
      return ChatSendResult.sendFailed;
    }

    // ── 9. Update spam guard state ───────────────────────────────────────
    _lastSentAt = DateTime.now();
    _lastSentText = text;
    _startCooldown(_cooldownSeconds);

    return ChatSendResult.success;
  }

  // ════════════════════════════════════════════════════════════════════════
  // Reactions
  // ════════════════════════════════════════════════════════════════════════

  Future<void> sendReaction(String messageId, String emoji, {required bool isGlobal}) async {
    if (_myUserId.isEmpty) return;

    final channel = isGlobal ? _globalChannel : _roomChannel;
    if (channel == null) return;

    // Optimistic update
    _applyReaction(messageId, emoji, _myUserId, isGlobal: isGlobal);

    final payload = {
      'message_id': messageId,
      'emoji': emoji,
      'user_id': _myUserId,
    };

    try {
      await channel.sendBroadcastMessage(
        event: 'reaction',
        payload: payload,
      );
    } catch (_) {
      // Roll back on failure (toggle again)
      _applyReaction(messageId, emoji, _myUserId, isGlobal: isGlobal);
    }
  }

  void _onIncomingReaction(Map<String, dynamic> payload, {required bool isGlobal}) {
    final messageId = payload['message_id'] as String?;
    final emoji = payload['emoji'] as String?;
    final userId = payload['user_id'] as String?;

    if (messageId == null || emoji == null || userId == null) return;
    if (userId == _myUserId) return; // Prevent duplicate if self=true

    _applyReaction(messageId, emoji, userId, isGlobal: isGlobal);
  }

  void _applyReaction(String messageId, String emoji, String userId, {required bool isGlobal}) {
    final list = isGlobal ? _globalMessages : _roomMessages;
    final index = list.indexWhere((msg) => msg.messageId == messageId);
    if (index == -1) return;

    final msg = list[index];
    final currentReactions = msg.reactions[emoji] ?? {};

    // Toggle reaction
    if (currentReactions.contains(userId)) {
      currentReactions.remove(userId);
      if (currentReactions.isEmpty) {
        msg.reactions.remove(emoji);
      }
    } else {
      currentReactions.add(userId);
      msg.reactions[emoji] = currentReactions;
    }

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Internal helpers
  // ════════════════════════════════════════════════════════════════════════

  void _onIncomingMessage(Map<String, dynamic> payload, {required bool isGlobal}) {
    final msg = ChatMessage.fromBroadcast(payload);
    if (msg.userId == _myUserId) return; // Prevent duplicate if self=true

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
    _authSubscription?.cancel(); // Fix #6: clean up auth listener
    leaveGlobalChat();
    leaveRoomChat();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Result enum for send operations
// ════════════════════════════════════════════════════════════════════════════

enum ChatSendResult {
  success,
  empty,
  tooLong,
  onCooldown,
  duplicate,
  notConnected,
  sendFailed; // Fix #4: transport-level failure after optimistic rollback

  String get userMessage => switch (this) {
        ChatSendResult.success => '',
        ChatSendResult.empty => 'Message cannot be empty.',
        ChatSendResult.tooLong => 'Max 120 characters allowed.',
        ChatSendResult.onCooldown => 'Please wait before sending again.',
        ChatSendResult.duplicate => 'You already sent that message.',
        ChatSendResult.notConnected => 'Chat not connected. Please wait.',
        ChatSendResult.sendFailed => 'Failed to send. Please try again.',
      };
}
