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
  final String threadId;
  final String? staffName;

  const ChatScreen({
    super.key,
    required this.threadId,
    this.staffName,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  Timer? _pollTimer;

  Future<void> _loadMessages() async {
    final response = await _service.getMessages(widget.threadId);
    setState(() {
      _messages = response.data ?? [];
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final result = await _service.sendMessage(
      threadId: widget.threadId,
      message: text,
    );

    if (result.success == true) {
      await _loadMessages();
    } else if (mounted) {
      showAppSnackBar(
        context,
        message: result.message ?? 'Failed to send message',
        tone: AppFeedbackTone.error,
      );
    }
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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.ocean.withValues(alpha: 0.1),
                  child:
                      const Icon(Icons.person, color: AppTheme.ink, size: 18),
                ),
                const SizedBox(width: 10),
                CustomText(
                  widget.staffName ?? 'Sales Rep',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: AppTheme.ink,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final ok = await _service.closeThread(widget.threadId);
                  if (!mounted) return;
                  showAppSnackBar(
                    context,
                    message: ok ? 'Thread closed' : 'Close failed',
                    tone:
                        ok ? AppFeedbackTone.success : AppFeedbackTone.error,
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          filled: true,
                          fillColor: const Color(0xFFF4F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accent,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
