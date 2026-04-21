import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
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
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    final amountText = invoice.amount != null
        ? 'N${NumberFormat('#,##0').format(invoice.amount)}'
        : 'N0';

    return GestureDetector(
      onTap: onOpen,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    invoice.reference ?? 'Invoice',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: deepBlue,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    amountText,
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),
            if ((invoice.status ?? '').isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomText(
                  invoice.status!,
                  fontSize: 9.5.sp,
                  color: deepBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
