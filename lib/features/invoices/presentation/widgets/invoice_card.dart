import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/invoice.dart';

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
    final status = (invoice.status ?? 'pending').toLowerCase();
    final isPaid = status == 'paid';
    final statusColor = isPaid ? const Color(0xFF0E7C66) : AppTheme.accent;
    final statusBg = isPaid ? const Color(0xFFE9F8F1) : const Color(0xFFFFF0E0);
    final statusLabel = isPaid ? 'Paid' : 'Awaiting payment';

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onOpen,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPaid
                          ? [
                              const Color(0xFF0E7C66),
                              const Color(0xFF42B79E),
                            ]
                          : [
                              AppTheme.accent,
                              const Color(0xFFFFB75E),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        invoice.reference ?? 'Invoice',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.ink,
                      ),
                      const SizedBox(height: 5),
                      CustomText(
                        dateText,
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: CustomText(
                    statusLabel,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MetaBlock(
                      label: 'Amount',
                      value: amountText,
                      valueColor: AppTheme.ink,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: AppTheme.ink.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _MetaBlock(
                      label: 'Action',
                      value: isPaid ? 'View receipt' : 'Pay or copy link',
                      valueColor: statusColor,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    isPaid
                        ? 'Payment is complete and your receipt is ready.'
                        : 'Open this invoice to pay now, copy the payment link, or view the PDF.',
                    fontSize: 12.7,
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 11.8,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.48),
        ),
        const SizedBox(height: 6),
        CustomText(
          value,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          color: valueColor,
        ),
      ],
    );
  }
}
