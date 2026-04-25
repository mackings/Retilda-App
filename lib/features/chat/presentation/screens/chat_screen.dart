import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Chat/api/chat_service.dart';
import 'package:retilda/Views/Chat/widgets/chat_bubble.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/chat.dart';
import 'package:sizer/sizer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    this.staffName,
  });

  final String threadId;
  final String? staffName;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  Future<void> _loadMessages() async {
    final response = await _service.getMessages(widget.threadId);
    if (!mounted) return;
    setState(() {
      _messages = response.data ?? [];
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    final result = await _service.sendMessage(
      threadId: widget.threadId,
      message: text,
    );

    if (!mounted) return;

    if (result.success == true) {
      await _loadMessages();
    } else {
      showAppSnackBar(
        context,
        message: result.message ?? 'Failed to send message',
        tone: AppFeedbackTone.error,
      );
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    }

    if (mounted) {
      setState(() => _sending = false);
    }
  }

  Future<void> _closeThread() async {
    final ok = await _service.closeThread(widget.threadId);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: ok ? 'Thread closed' : 'Close failed',
      tone: ok ? AppFeedbackTone.success : AppFeedbackTone.error,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    final chatTitle = widget.staffName ?? 'Sales support';

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            titleSpacing: 12,
            title: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF103C57), Color(0xFF145E8D)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        chatTitle,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.2.sp,
                        color: AppTheme.ink,
                      ),
                      CustomText(
                        'Support conversation',
                        fontSize: 10.5.sp,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _closeThread,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.chat_outlined,
                          color: AppTheme.ocean,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'Live support thread',
                              fontSize: 13.6,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              'Messages refresh automatically every few seconds.',
                              fontSize: 12.1,
                              color: Colors.black.withValues(alpha: 0.56),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _EmptyConversationState(
                            staffName: chatTitle,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              reverse: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    _messages[_messages.length - 1 - index];
                                final isMe = message.senderType == 'user';
                                return ChatBubble(
                                  message: message.message ?? '',
                                  isMe: isMe,
                                  timestamp: message.createdAt,
                                );
                              },
                            ),
                          ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              filled: true,
                              fillColor: const Color(0xFFF4F7FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _sending
                                  ? const [
                                      Color(0xFFB7C1CA),
                                      Color(0xFFD0D8DE),
                                    ]
                                  : const [
                                      Color(0xFFFB9324),
                                      Color(0xFFFFB75E),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: IconButton(
                            icon: _sending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                            onPressed: _sending ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState({
    required this.staffName,
  });

  final String staffName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppTheme.accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              CustomText(
                'Start the conversation',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
              const SizedBox(height: 8),
              CustomText(
                'Your messages with $staffName will appear here as soon as you send the first one.',
                fontSize: 12.9,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
