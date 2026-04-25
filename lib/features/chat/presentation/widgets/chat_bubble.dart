import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/theme/app_theme.dart';
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
    final timeLabel = _formatTimestamp(timestamp);
    final bubbleColor = isMe ? AppTheme.ink : Colors.white;
    final textColor = isMe ? Colors.white : AppTheme.ink;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF103C57), Color(0xFF145E8D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMe ? 22 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 22),
          ),
          border: Border.all(
            color: isMe
                ? Colors.transparent
                : AppTheme.ink.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: bubbleColor.withValues(alpha: isMe ? 0.18 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            CustomText(
              message,
              fontSize: 13.2.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            if (timeLabel != null) ...[
              const SizedBox(height: 4),
              CustomText(
                timeLabel,
                fontSize: 10.sp,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
