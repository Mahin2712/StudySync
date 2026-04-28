import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Aeon Slate Design Tokens (mirrored from RoomDetailScreen)
// ─────────────────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0C0E11);
const _surface = Color(0xFF111417);
const _surfaceHigh = Color(0xFF1C2025);
const _surfaceHighest = Color(0xFF22262C);
const _primary = Color(0xFFADCBDB);
const _primaryGlow = Color(0x1AADCBDB); // 10% opacity glow
const _onSurface = Color(0xFFE2E5EE);
const _onSurfaceVariant = Color(0xFFA7ABB3);
const _outline = Color(0xFF44484F);

// ─────────────────────────────────────────────────────────────────────────────
// Public helper — shows the chat bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the dual-layer chat bottom sheet.
///
/// [isGlobal] — true for Global Platform Chat, false for Room Chat.
/// [chatService] — the singleton [ChatService] instance.
void showChatBottomSheet(
  BuildContext context, {
  required ChatService chatService,
  required bool isGlobal,
  String? roomName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ChatSheet(
      chatService: chatService,
      isGlobal: isGlobal,
      roomName: roomName,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Private: Chat Sheet Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChatSheet extends StatefulWidget {
  final ChatService chatService;
  final bool isGlobal;
  final String? roomName;

  const _ChatSheet({
    required this.chatService,
    required this.isGlobal,
    this.roomName,
  });

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  ChatService get _svc => widget.chatService;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _svc.removeListener(_onServiceUpdate);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
    // Scroll to newest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final result = _svc.sendMessage(
      _inputCtrl.text,
      isGlobal: widget.isGlobal,
    );

    if (result == ChatSendResult.success) {
      _inputCtrl.clear();
    } else if (result != ChatSendResult.empty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.userMessage, style: const TextStyle(fontFamily: 'Inter')),
          backgroundColor: _surfaceHighest,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<ChatMessage> get _messages =>
      widget.isGlobal ? _svc.globalMessages : _svc.roomMessages;

  @override
  Widget build(BuildContext context) {
    final title = widget.isGlobal
        ? 'Global Chat'
        : '${widget.roomName ?? 'Room'} Chat';

    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.25,
      maxChildSize: 0.88,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              _DragHandle(),

              // ── Header ───────────────────────────────────────────────
              _SheetHeader(
                title: title,
                isGlobal: widget.isGlobal,
                messageCount: _messages.length,
                onClose: () => Navigator.of(context).pop(),
              ),

              // ── Message List ─────────────────────────────────────────
              Expanded(
                child: _messages.isEmpty
                    ? _EmptyState(isGlobal: widget.isGlobal)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _MessageBubble(
                          message: _messages[i],
                          isMe: _messages[i].userId == (Supabase.instance.client.auth.currentUser?.id ?? ''),
                        ),
                      ),
              ),

              // ── Input Row ────────────────────────────────────────────
              _InputRow(
                controller: _inputCtrl,
                focusNode: _focusNode,
                cooldownRemaining: _svc.cooldownRemaining,
                isOnCooldown: _svc.isOnCooldown,
                onSend: _handleSend,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      decoration: BoxDecoration(
        color: _outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final bool isGlobal;
  final int messageCount;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.title,
    required this.isGlobal,
    required this.messageCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            isGlobal ? Icons.public_rounded : Icons.forum_rounded,
            color: _primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          if (messageCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$messageCount',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20, color: _onSurfaceVariant),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isGlobal;
  const _EmptyState({required this.isGlobal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isGlobal ? Icons.public_rounded : Icons.chat_bubble_outline_rounded,
            size: 40,
            color: _outline,
          ),
          const SizedBox(height: 12),
          Text(
            isGlobal
                ? 'No global messages yet.\nBe the first to say hi! 👋'
                : 'No messages in this room yet.\nStart the conversation! 📚',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PurnoBCC',
              fontSize: 13,
              color: _onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  // isMe is a bool, not a String — fixing constructor
  const _MessageBubble({required this.message, required this.isMe});

  String get _initial => message.username.isNotEmpty
      ? message.username[0].toUpperCase()
      : '?';

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.username,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      // PurnoBCC handles Bangla glyphs; Inter handles Latin
                      fontFamily: 'PurnoBCC',
                      fontSize: 14,
                      color: _onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int cooldownRemaining;
  final bool isOnCooldown;
  final VoidCallback onSend;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.cooldownRemaining,
    required this.isOnCooldown,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _outline.withValues(alpha: 0.4), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _outline.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLength: 120,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(
                  fontFamily: 'PurnoBCC',
                  fontSize: 14,
                  color: _onSurface,
                  height: 1.3,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message... (emoji welcome 🔥)',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: _onSurfaceVariant,
                    fontSize: 13,
                  ),
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send Button with cooldown ring overlay
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cooldown progress ring
                if (isOnCooldown)
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: cooldownRemaining / 3.0,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                      backgroundColor: _outline.withValues(alpha: 0.3),
                    ),
                  ),
                // Send icon
                Material(
                  color: isOnCooldown
                      ? _surfaceHigh
                      : _primary.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isOnCooldown ? null : onSend,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isOnCooldown
                            ? []
                            : [
                                BoxShadow(
                                  color: _primaryGlow,
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: isOnCooldown ? _onSurfaceVariant : _primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
