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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 8),
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
              color: isMe ? Colors.white : AppTheme.ink,
            ),
            if (timeLabel != null) ...[
              const SizedBox(height: 4),
              CustomText(
                timeLabel,
                fontSize: 10.sp,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
