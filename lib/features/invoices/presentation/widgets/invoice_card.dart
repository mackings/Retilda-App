import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/invoice.dart';
import 'package:sizer/sizer.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onOpen;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = invoice.amount != null
        ? 'N${NumberFormat('#,##0').format(invoice.amount)}'
        : 'N0';
    final dateText = invoice.createdAt == null
        ? 'Recently created'
        : DateFormat('dd MMM yyyy').format(
            DateTime.tryParse(invoice.createdAt!) ?? DateTime.now(),
          );

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    invoice.reference ?? 'Invoice',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: AppTheme.ink,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    amountText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                  const SizedBox(height: 3),
                  CustomText(
                    dateText,
                    fontSize: 11.5,
                    color: Colors.black.withValues(alpha: 0.58),
                  ),
                ],
              ),
            ),
            if ((invoice.status ?? '').isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (invoice.status?.toLowerCase() == 'paid'
                          ? const Color(0xFFE8F7F2)
                          : const Color(0xFFFFF1E8))
                      .withValues(alpha: 1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: CustomText(
                  invoice.status!,
                  fontSize: 10.2.sp,
                  fontWeight: FontWeight.w800,
                  color: invoice.status?.toLowerCase() == 'paid'
                      ? const Color(0xFF0E7C66)
                      : const Color(0xFFB54708),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
