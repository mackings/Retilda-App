import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/admin/data/data_sources/admin_user_service.dart';
import 'package:retilda/features/admin/data/models/admin_model.dart';

class PurchaseDetailsModal extends StatefulWidget {
  final GlanceUser user;
  final int pageSize;

  const PurchaseDetailsModal({
    super.key,
    required this.user,
    this.pageSize = 20,
  });

  @override
  State<PurchaseDetailsModal> createState() => _PurchaseDetailsModalState();
}

class _PurchaseDetailsModalState extends State<PurchaseDetailsModal> {
  late Future<GlanceUserPurchasesPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPurchases();
  }

  Future<GlanceUserPurchasesPage> _loadPurchases() {
    return ApiService.fetchUserPurchases(
      userId: widget.user.id,
      page: 1,
      limit: widget.pageSize,
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Not available';
    }
    try {
      return DateFormat('d MMM, yyyy • h:mm a').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'en_NG');
    return 'N${formatter.format(amount)}';
  }

  Color _deliveryAccent(GlancePurchase purchase) {
    final status = purchase.deliveryPaymentStatus ?? '';
    if (status == 'paid' || purchase.deliveryRequested) {
      return const Color(0xFF1E8E5A);
    }
    if (status == 'pending') {
      return AppTheme.accent;
    }
    return AppTheme.ocean;
  }

  String _deliveryLabel(GlancePurchase purchase) {
    final status = purchase.deliveryPaymentStatus ?? '';
    if (status == 'paid' || purchase.deliveryRequested) {
      return 'Delivery paid';
    }
    if (status == 'pending') {
      return 'Delivery pending';
    }
    return purchase.deliveryStatus.isEmpty
        ? 'Delivery not started'
        : purchase.deliveryStatus;
  }

  @override
  Widget build(BuildContext context) {
    final seedSummary = GlancePurchasesSummary(
      totalPurchases: widget.user.purchaseSummary.purchaseCount,
      totalAmountPaid: widget.user.purchaseSummary.totalAmountPaid,
      totalAmountToPay: widget.user.purchaseSummary.totalAmountToPay,
      completedDeliveryCount:
          widget.user.purchaseSummary.completedDeliveryCount,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<GlanceUserPurchasesPage>(
            future: _future,
            builder: (context, snapshot) {
              final response = snapshot.data;
              final currentUser = response?.user ?? widget.user;
              final summary = response?.summary ?? seedSummary;
              final purchases = response?.purchases ?? const <GlancePurchase>[];

              return CustomScrollView(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ModalHero(
                        user: currentUser,
                        summary: summary,
                        formatAmount: _formatAmount,
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _SummaryStrip(
                        totalPaid: summary.totalAmountPaid,
                        pendingAmount: summary.totalAmountToPay >
                                summary.totalAmountPaid
                            ? summary.totalAmountToPay - summary.totalAmountPaid
                            : 0,
                        deliveries: summary.completedDeliveryCount,
                        formatAmount: _formatAmount,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            'Purchase timeline',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${summary.totalPurchases} purchase${summary.totalPurchases == 1 ? '' : 's'}',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: _PurchaseCardSkeleton(),
                        ),
                        childCount: 3,
                      ),
                    )
                  else if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        child: _ErrorPanel(
                          onRetry: () {
                            setState(() {
                              _future = _loadPurchases();
                            });
                          },
                        ),
                      ),
                    )
                  else if (purchases.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        child: _EmptyPanel(),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final purchase = purchases[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: _PurchaseCard(
                              purchase: purchase,
                              formatAmount: _formatAmount,
                              formatDate: _formatDate,
                              deliveryAccent: _deliveryAccent(purchase),
                              deliveryLabel: _deliveryLabel(purchase),
                            ),
                          );
                        },
                        childCount: purchases.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModalHero extends StatelessWidget {
  final GlanceUser user;
  final GlancePurchasesSummary summary;
  final String Function(num amount) formatAmount;
  final VoidCallback onClose;

  const _ModalHero({
    required this.user,
    required this.summary,
    required this.formatAmount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatAmount(summary.totalAmountPaid),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total collected from this customer',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double totalPaid;
  final double pendingAmount;
  final int deliveries;
  final String Function(num amount) formatAmount;

  const _SummaryStrip({
    required this.totalPaid,
    required this.pendingAmount,
    required this.deliveries,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryStatTile(
            label: 'Paid',
            value: formatAmount(totalPaid),
            accent: AppTheme.ocean,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryStatTile(
            label: 'Pending',
            value: formatAmount(pendingAmount),
            accent: AppTheme.accent,
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryStatTile(
            label: 'Delivered',
            value: '$deliveries',
            accent: const Color(0xFF1E8E5A),
            icon: Icons.local_shipping_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _SummaryStatTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.54),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final GlancePurchase purchase;
  final String Function(num amount) formatAmount;
  final String Function(String? date) formatDate;
  final Color deliveryAccent;
  final String deliveryLabel;

  const _PurchaseCard({
    required this.purchase,
    required this.formatAmount,
    required this.formatDate,
    required this.deliveryAccent,
    required this.deliveryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final outstanding = purchase.amountToPay > purchase.paidAmount
        ? purchase.amountToPay - purchase.paidAmount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              (purchase.isCompleted ? const Color(0xFF1E8E5A) : AppTheme.ocean)
                  .withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  purchase.product.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: purchase.isCompleted ? 'Completed' : 'Ongoing',
                color: purchase.isCompleted
                    ? const Color(0xFF1E8E5A)
                    : AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                  label: 'Plan ${purchase.paymentPlan}', color: AppTheme.ocean),
              _StatusBadge(label: deliveryLabel, color: deliveryAccent),
              if ((purchase.purchaseType ?? '').isNotEmpty)
                _StatusBadge(
                  label: purchase.purchaseType!.replaceAll('_', ' '),
                  color: AppTheme.ink,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MoneyTile(
                  label: 'Paid',
                  value: formatAmount(purchase.paidAmount),
                  accent: AppTheme.ocean,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyTile(
                  label: 'Target',
                  value: formatAmount(purchase.amountToPay),
                  accent: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyTile(
                  label: 'Outstanding',
                  value: formatAmount(outstanding),
                  accent: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Created',
                  value: formatDate(purchase.createdAt),
                ),
                if ((purchase.deliveryPaymentReference ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.receipt_long_rounded,
                    label: 'Delivery ref',
                    value: purchase.deliveryPaymentReference!,
                  ),
                ],
                if (purchase.payments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Latest installment',
                    value:
                        '${formatAmount(purchase.payments.first.amountPaid)} of ${formatAmount(purchase.payments.first.amountToPay)}',
                  ),
                ],
              ],
            ),
          ),
          if (purchase.payments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Payment records',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            ...purchase.payments.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (payment.status == 'completed'
                              ? const Color(0xFF1E8E5A)
                              : AppTheme.accent)
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(
                            label: payment.status.toUpperCase(),
                            color: payment.status == 'completed'
                                ? const Color(0xFF1E8E5A)
                                : AppTheme.accent,
                          ),
                          const Spacer(),
                          Text(
                            formatDate(payment.paymentDate),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${formatAmount(payment.amountPaid)} paid of ${formatAmount(payment.amountToPay)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next payment: ${formatDate(payment.nextPaymentDate)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MoneyTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.ocean),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _PurchaseCardSkeleton extends StatelessWidget {
  const _PurchaseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
            child: Container(
              height: index == 0 ? 20 : 14,
              width: index == 0
                  ? 180
                  : index == 1
                      ? 130
                      : double.infinity,
              decoration: BoxDecoration(
                color: index == 0 ? Colors.grey.shade200 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPanel({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 42, color: AppTheme.accent),
          const SizedBox(height: 12),
          Text(
            'Unable to load purchases',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 42, color: AppTheme.ocean),
          const SizedBox(height: 12),
          Text(
            'No purchases found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
