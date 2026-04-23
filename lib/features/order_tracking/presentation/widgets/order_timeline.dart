import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/core/theme/app_theme.dart';

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({
    super.key,
    required this.currentStatus,
  });

  final String currentStatus;

  static const List<_TimelineStep> _steps = [
    _TimelineStep(
      status: 'processing',
      label: 'Processing',
      description: 'Your order has been confirmed and is being prepared.',
      icon: Icons.inventory_2_outlined,
    ),
    _TimelineStep(
      status: 'ready',
      label: 'Ready',
      description: 'Everything is packed and queued for dispatch.',
      icon: Icons.check_circle_outline_rounded,
    ),
    _TimelineStep(
      status: 'out_for_delivery',
      label: 'Out for Delivery',
      description: 'Your order is currently with the delivery team.',
      icon: Icons.local_shipping_outlined,
    ),
    _TimelineStep(
      status: 'delivered',
      label: 'Delivered',
      description: 'The delivery has been completed successfully.',
      icon: Icons.home_work_outlined,
    ),
  ];

  int _currentIndex() {
    final index = _steps.indexWhere((step) => step.status == currentStatus);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking timeline',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A clear view of where this order is right now.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == _steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.ocean
                            : const Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppTheme.ocean.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        color: isCompleted ? Colors.white : Colors.black45,
                        size: 22,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 52,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.ocean.withValues(alpha: 0.32)
                              : const Color(0xFFE6EBF1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFFF5FAFE)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.ocean.withValues(alpha: 0.24)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  step.label,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppTheme.accent.withValues(alpha: 0.14)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isCurrent
                                      ? 'Current'
                                      : isCompleted
                                          ? 'Done'
                                          : 'Pending',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isCompleted
                                        ? AppTheme.accent
                                        : Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.description,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.status,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String status;
  final String label;
  final String description;
  final IconData icon;
}
