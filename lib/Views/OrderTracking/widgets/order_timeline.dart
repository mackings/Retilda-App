import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class OrderTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderTimeline({super.key, required this.currentStatus});

  static const List<String> steps = [
    'processing',
    'ready',
    'out_for_delivery',
    'delivered',
  ];

  int _currentIndex() {
    final idx = steps.indexOf(currentStatus);
    return idx < 0 ? 0 : idx;
  }

  String _labelFor(String status) {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Processing';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFFB9324);
    const Color deepBlue = Color(0xFF103C57);
    final currentIndex = _currentIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Order status',
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: deepBlue,
          ),
          const SizedBox(height: 14),
          Column(
            children: List.generate(steps.length, (index) {
              final isDone = index <= currentIndex;
              final isLast = index == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDone ? accent : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 34,
                          color: isDone ? accent : Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            _labelFor(steps[index]),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5.sp,
                            color: isDone ? deepBlue : Colors.grey[600],
                          ),
                          if (!isLast) const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
