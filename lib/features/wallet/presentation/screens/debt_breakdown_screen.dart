import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/presentation/widgets/webview.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';
import 'package:retilda/features/wallet/presentation/providers/debt_providers.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_api_providers.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:sizer/sizer.dart';

class DebtBreakdownScreen extends ConsumerStatefulWidget {
  const DebtBreakdownScreen({super.key});

  @override
  ConsumerState<DebtBreakdownScreen> createState() =>
      _DebtBreakdownScreenState();
}

class _DebtBreakdownScreenState extends ConsumerState<DebtBreakdownScreen> {
  bool _isLoading = false;
  String? _activeAction;

  String _formatMoney(num amount) {
    return 'N${NumberFormat('#,##0.00').format(amount)}';
  }

  Future<void> _showConfirmationSheet({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    await showAppNoticeSheet<void>(
      context: context,
      title: title,
      message: message,
      tone: AppFeedbackTone.info,
      primaryLabel: confirmLabel,
      secondaryLabel: 'Cancel',
      icon: icon,
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        onConfirm();
      },
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _handlePayWallet(DebtPurchase purchase) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _activeAction = '${purchase.purchaseId}_wallet';
    });

    final result = await ref
        .read(walletApiServiceProvider)
        .payDebtUsingWallet(purchase.purchaseId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _activeAction = null;
    });

    if (result['success'] == true) {
      ref.invalidate(debtSummaryProvider);
      ref.invalidate(walletOverviewProvider);
      await showAppAlert(
        context: context,
        title: 'Debt paid',
        message: result['message'] ?? 'Late fees paid successfully.',
        tone: AppFeedbackTone.success,
        buttonText: 'Done',
        icon: Icons.check_circle_outline_rounded,
      );
      return;
    }

    await showAppAlert(
      context: context,
      title: 'Payment failed',
      message: result['message'] ?? 'Unable to pay debt.',
      tone: AppFeedbackTone.error,
      buttonText: 'Okay',
      icon: Icons.error_outline_rounded,
    );
  }

  Future<void> _handlePayCard(DebtPurchase purchase) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _activeAction = '${purchase.purchaseId}_card';
    });

    final result = await ref
        .read(walletApiServiceProvider)
        .payDebtUsingCard(purchase.purchaseId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _activeAction = null;
    });

    if (result['success'] != true || result['paymentUrl'] == null) {
      await showAppAlert(
        context: context,
        title: 'Payment failed',
        message: result['message'] ?? 'Unable to start card payment.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: result['paymentUrl'],
          title: 'Pay debt with card',
        ),
      ),
    );

    if (!mounted) return;
    ref.invalidate(debtSummaryProvider);
    ref.invalidate(walletOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final debtState = ref.watch(debtSummaryProvider);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            title: CustomText(
              'Late fee debt',
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(debtSummaryProvider),
              ),
            ],
          ),
          body: debtState.when(
            loading: () => const Center(
              child: SizedBox(
                width: 180,
                child:
                    LinearProgressIndicator(color: AppTheme.accent, minHeight: 4),
              ),
            ),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[500]),
                    const SizedBox(height: 12),
                    CustomText(
                      'Unable to load debt summary',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(debtSummaryProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (debt) {
              if (!debt.hasDebt || debt.purchases.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 56,
                          color: Color(0xFF0E7C66),
                        ),
                        const SizedBox(height: 14),
                        CustomText(
                          'No outstanding late fees',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          "You're all caught up — nothing owed right now.",
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.accent,
                onRefresh: () async {
                  ref.invalidate(debtSummaryProvider);
                  await ref.read(debtSummaryProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF8D8B8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Total outstanding',
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB54708),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatMoney(debt.totalDebt),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB54708),
                            ),
                          ),
                          const SizedBox(height: 6),
                          CustomText(
                            '${debt.purchases.length} purchase${debt.purchases.length == 1 ? '' : 's'} with overdue installments',
                            fontSize: 12.sp,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...debt.purchases.map(
                      (purchase) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DebtPurchaseCard(
                          purchase: purchase,
                          isLoading: _isLoading,
                          activeAction: _activeAction,
                          formatMoney: _formatMoney,
                          onPayWallet: () => _showConfirmationSheet(
                            title: 'Confirm wallet payment',
                            message:
                                'Pay ${_formatMoney(purchase.purchaseDebt)} in late fees for ${purchase.productName} from your wallet?',
                            confirmLabel: 'Confirm and pay',
                            icon: Icons.account_balance_wallet_outlined,
                            onConfirm: () => _handlePayWallet(purchase),
                          ),
                          onPayCard: () => _showConfirmationSheet(
                            title: 'Confirm card payment',
                            message:
                                'Pay ${_formatMoney(purchase.purchaseDebt)} in late fees for ${purchase.productName} with your card?',
                            confirmLabel: 'Confirm and pay',
                            icon: Icons.credit_card_rounded,
                            onConfirm: () => _handlePayCard(purchase),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DebtPurchaseCard extends StatelessWidget {
  const _DebtPurchaseCard({
    required this.purchase,
    required this.isLoading,
    required this.activeAction,
    required this.formatMoney,
    required this.onPayWallet,
    required this.onPayCard,
  });

  final DebtPurchase purchase;
  final bool isLoading;
  final String? activeAction;
  final String Function(num) formatMoney;
  final VoidCallback onPayWallet;
  final VoidCallback onPayCard;

  @override
  Widget build(BuildContext context) {
    const deepBlue = AppTheme.ink;
    final isWalletActive = activeAction == '${purchase.purchaseId}_wallet';
    final isCardActive = activeAction == '${purchase.purchaseId}_card';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (purchase.productImage ?? '').isNotEmpty
                    ? Image.network(
                        purchase.productImage!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: const Color(0xFFEAF1F6),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: deepBlue,
                          ),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFFEAF1F6),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: deepBlue,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: deepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(purchase.purchaseDebt),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB54708),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: purchase.installments
                  .map((installment) => _DebtInstallmentRow(installment: installment))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final verticalLayout = constraints.maxWidth < 380;
              final walletButton = OutlinedButton(
                onPressed: isLoading ? null : onPayWallet,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isWalletActive
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Pay from wallet',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: deepBlue,
                        ),
                      ),
              );

              final cardButton = FilledButton(
                onPressed: isLoading ? null : onPayCard,
                style: FilledButton.styleFrom(
                  backgroundColor: deepBlue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isCardActive
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pay with card',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                      ),
              );

              if (verticalLayout) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: walletButton),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: cardButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: walletButton),
                  const SizedBox(width: 10),
                  Expanded(child: cardButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DebtInstallmentRow extends StatelessWidget {
  const _DebtInstallmentRow({required this.installment});

  final DebtInstallment installment;

  @override
  Widget build(BuildContext context) {
    final period = DateFormat('dd MMM yy').format(installment.missedPeriod);
    final formatter = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment #${installment.paymentIndex} · $period',
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${installment.weeksOverdue} week${installment.weeksOverdue == 1 ? '' : 's'} overdue · base N${formatter.format(installment.originalAmount)}',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'N${formatter.format(installment.lateFeeOutstanding)}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB54708),
            ),
          ),
        ],
      ),
    );
  }
}
