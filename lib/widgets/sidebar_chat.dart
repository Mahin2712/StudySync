import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SidebarChat extends StatefulWidget {
  final ChatService chatService;
  final bool isGlobal;

  const SidebarChat({
    super.key,
    required this.chatService,
    required this.isGlobal,
  });

  @override
  State<SidebarChat> createState() => _SidebarChatState();
}

class _SidebarChatState extends State<SidebarChat> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  String _spamWarning = '';
  bool _showSpamWarning = false;

  // Colors
  static const _surfaceHigh = Color(0xFF1C2025);
  static const _surfaceHighest = Color(0xFF22262C);
  static const _primary = Color(0xFFADCBDB);
  static const _primaryContainer = Color(0xFF395664);
  static const _onPrimaryContainer = Color(0xFFC9E8F8);
  static const _onSurface = Color(0xFFE2E5EE);
  static const _onSurfaceVariant = Color(0xFFA7ABB3);
  static const _outline = Color(0xFF44484F);
  static const _error = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showReactionPicker(BuildContext context, ChatMessage msg) {
    final emojis = ['👍', '🎉', '😂', '❤️', '🚀', '👀'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: emojis.map((emoji) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.chatService.sendReaction(
                    msg.messageId,
                    emoji,
                    isGlobal: widget.isGlobal,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReactions(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: msg.reactions.entries.map((e) {
          final emoji = e.key;
          final count = e.value.length;
          final iReacted = e.value.contains(_currentUserId);

          return GestureDetector(
            onTap: () {
              widget.chatService.sendReaction(
                msg.messageId,
                emoji,
                isGlobal: widget.isGlobal,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iReacted
                    ? _primary.withValues(alpha: 0.2)
                    : _surfaceHighest,
                border: Border.all(
                  color: iReacted ? _primary : _outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: iReacted ? _primary : _onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Fix #4: async so we can await the Future<ChatSendResult> from sendMessage().
  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final result = await widget.chatService.sendMessage(
      text,
      isGlobal: widget.isGlobal,
    );

    if (!mounted) return;

    if (result == ChatSendResult.success) {
      // Only clear input on confirmed success.
      _textController.clear();
      setState(() => _showSpamWarning = false);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      // Show the result's user-facing message as an inline warning.
      setState(() {
        _spamWarning = result.userMessage;
        _showSpamWarning = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSpamWarning = false);
      });
    }
  }

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x1AA7ABB3))),
          ),
          child: Row(
            children: [
              Icon(
                widget.isGlobal
                    ? Icons.public_rounded
                    : Icons.meeting_room_rounded,
                color: _primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isGlobal ? 'Global Chat' : 'Room Chat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
            ],
          ),
        ),

        // Chat Messages
        Expanded(
          child: ListenableBuilder(
            listenable: widget.chatService,
            builder: (context, _) {
              final messages = widget.isGlobal
                  ? widget.chatService.globalMessages
                  : widget.chatService.roomMessages;

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet.\nBe the first to say hello!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.userId == _currentUserId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          _buildAvatar(msg.username),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onLongPress: () =>
                                    _showReactionPicker(context, msg),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? _primaryContainer
                                        : _surfaceHigh,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 4 : 16,
                                      ),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: _outline.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            msg.username,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _primary,
                                              fontFamilyFallback: ['PurnoBCC'],
                                            ),
                                          ),
                                        ),
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isMe
                                              ? _onPrimaryContainer
                                              : _onSurface,
                                          fontFamilyFallback: const [
                                            'PurnoBCC',
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (msg.reactions.isNotEmpty)
                                _buildReactions(msg),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Spam Warning & Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: _surfaceHighest,
            border: Border(top: BorderSide(color: Color(0x1AA7ABB3))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed-height inline spam warning placeholder
              SizedBox(
                height: 18,
                child: AnimatedOpacity(
                  opacity: _showSpamWarning ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _spamWarning,
                    style: const TextStyle(
                      color: _error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: _onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _focusNode.hasFocus
                            ? null
                            : 'Type a message...',
                        hintStyle: const TextStyle(color: _onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: _surfaceHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: _onPrimaryContainer,
                        size: 18,
                      ),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _primaryContainer.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
