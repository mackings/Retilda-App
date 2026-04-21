import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/review.dart';
import 'package:sizer/sizer.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    final dateText = review.createdAt != null
        ? DateFormat('dd MMM yy').format(DateTime.parse(review.createdAt!))
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: deepBlue.withOpacity(0.1),
                child: const Icon(Icons.person, color: deepBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      review.user?.fullName ?? 'Anonymous',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5.sp,
                      color: deepBlue,
                    ),
                    if (dateText.isNotEmpty)
                      CustomText(
                        dateText,
                        fontSize: 10.5.sp,
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final filled = (review.rating ?? 0) > index;
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 16,
                    color: filled ? const Color(0xFFFB9324) : Colors.grey[400],
                  );
                }),
              )
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            CustomText(
              review.comment ?? '',
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ]
        ],
      ),
    );
  }
}
