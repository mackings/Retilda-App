import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Chat/widgets/chat_bubble.dart';
import 'package:retilda/Views/Staff/api/staff_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/chat.dart';
import 'package:sizer/sizer.dart';

class StaffChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const StaffChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StaffChatScreenState();
}

class _StaffChatScreenState extends ConsumerState<StaffChatScreen> {
  final StaffService _service = StaffService();
  final TextEditingController _messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  Timer? _pollTimer;

  Future<void> _loadMessages() async {
    final response = await _service.getStaffMessages(widget.threadId);
    setState(() {
      _messages = response.data ?? [];
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final result = await _service.sendStaffMessage(
      threadId: widget.threadId,
      message: text,
    );

    if (result.success == true) {
      await _loadMessages();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to send message')),
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
    const Color deepBlue = Color(0xFF103C57);

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
                  backgroundColor: deepBlue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: deepBlue, size: 18),
                ),
                const SizedBox(width: 10),
                CustomText(
                  'Customer',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: deepBlue,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final ok = await _service.closeStaffThread(widget.threadId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Thread closed' : 'Close failed'),
                    ),
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
                            final isMe = message.senderType == 'staff';
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
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
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFB9324),
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
