import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String? timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.timestamp,
  });

  String? _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateFormat('h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    final timeLabel = _formatTimestamp(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? accent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            CustomText(
              message,
              fontSize: 13.sp,
              color: isMe ? Colors.white : deepBlue,
            ),
            if (timeLabel != null) ...[
              const SizedBox(height: 4),
              CustomText(
                timeLabel,
                fontSize: 9.5.sp,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
