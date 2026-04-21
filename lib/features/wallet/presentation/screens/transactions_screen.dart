import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_overview.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:sizer/sizer.dart';

class Transactions extends ConsumerWidget {
  const Transactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(walletOverviewProvider);
    final filter = ref.watch(walletTransactionFilterProvider);
    final filteredTransactions = ref.watch(filteredWalletTransactionsProvider);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: CustomText(
              'Transactions',
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(walletOverviewProvider),
              ),
            ],
          ),
          body: overviewState.when(
            loading: () => const _WalletLoadingView(),
            error: (_, __) => _WalletErrorView(
              onRetry: () => ref.invalidate(walletOverviewProvider),
            ),
            data: (overview) {
              return RefreshIndicator(
                color: AppTheme.accent,
                onRefresh: () async {
                  ref.invalidate(walletOverviewProvider);
                  await ref.read(walletOverviewProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _WalletBalanceCard(overview: overview),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            'Transaction History',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TransactionFilterChips(
                      selected: filter,
                      onChanged: (value) {
                        ref
                            .read(walletTransactionFilterProvider.notifier)
                            .state = value;
                      },
                    ),
                    const SizedBox(height: 14),
                    if (overview.transactions.isEmpty)
                      const _EmptyTransactions()
                    else
                      ...filteredTransactions.reversed.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionTile(transaction: transaction),
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

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.overview});

  final WalletOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 12),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Available Balance',
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                const SizedBox(height: 6),
                CustomText(
                  'N${_formatBalance(overview.balance)}',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                const SizedBox(height: 14),
                CustomText(
                  overview.accountNumber ?? 'No account number',
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
                const SizedBox(height: 3),
                CustomText(
                  overview.bankName,
                  color: Colors.white70,
                  fontSize: 11.sp,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: overview.accountNumber == null
                ? null
                : () => _showBankDetailsModal(context, overview),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  static String _formatBalance(double? balance) {
    if (balance == null) return '****';
    return balance.toStringAsFixed(1).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  static void _showBankDetailsModal(
    BuildContext context,
    WalletOverview overview,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.25,
          initialChildSize: 0.35,
          maxChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          'Wallet top-up',
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  CustomText(
                    'Send a transfer to fund your wallet.',
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.ocean.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Bank', value: overview.bankName),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: 'Account Number',
                          value: overview.accountNumber ?? '',
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 22),
                            onPressed: () {
                              final accountNumber =
                                  overview.accountNumber ?? '';
                              Clipboard.setData(
                                ClipboardData(text: accountNumber),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account number copied'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomText(
                    'Funds reflect automatically once your transfer clears.',
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(label, fontSize: 12.sp, color: Colors.grey[700]),
              const SizedBox(height: 5),
              CustomText(
                value,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TransactionFilterChips extends StatelessWidget {
  const _TransactionFilterChips({
    required this.selected,
    required this.onChanged,
  });

  final WalletTransactionFilter selected;
  final ValueChanged<WalletTransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          selected: selected == WalletTransactionFilter.all,
          onSelected: () => onChanged(WalletTransactionFilter.all),
        ),
        _FilterChip(
          label: 'Debit',
          selected: selected == WalletTransactionFilter.debit,
          onSelected: () => onChanged(WalletTransactionFilter.debit),
        ),
        _FilterChip(
          label: 'Credit',
          selected: selected == WalletTransactionFilter.credit,
          onSelected: () => onChanged(WalletTransactionFilter.credit),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'en_NG',
      symbol: 'N',
      decimalDigits: 0,
    ).format(transaction.amount);
    final date = DateFormat('MMMM d, yyyy, h:mma').format(
      transaction.transactionDate.add(const Duration(hours: 1)),
    );
    final color = transaction.isDebit ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isDebit ? Icons.south_east : Icons.north_east,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  transaction.displayTitle,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
                const SizedBox(height: 4),
                CustomText(
                  transaction.description,
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 4),
                CustomText(date, fontSize: 12.sp, color: Colors.grey[600]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                amount,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: transaction.isSuccess
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: CustomText(
                  transaction.status,
                  fontSize: 12.sp,
                  color: transaction.isSuccess ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletLoadingView extends StatelessWidget {
  const _WalletLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 180,
        child: LinearProgressIndicator(color: AppTheme.accent, minHeight: 4),
      ),
    );
  }
}

class _WalletErrorView extends StatelessWidget {
  const _WalletErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            CustomText(
              'Unable to load wallet',
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
            const SizedBox(height: 8),
            CustomText(
              'Check your connection and try again.',
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          CustomText(
            'No transactions available',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
          const SizedBox(height: 6),
          CustomText(
            'Your transactions will appear here once you start paying.',
            fontSize: 13.sp,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
