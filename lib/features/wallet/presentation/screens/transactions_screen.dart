import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_overview.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:sizer/sizer.dart';

class Transactions extends ConsumerStatefulWidget {
  const Transactions({super.key});

  @override
  ConsumerState<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends ConsumerState<Transactions>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(walletOverviewProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
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

  static final NumberFormat _balanceFormatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 188),
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
      padding: const EdgeInsets.all(18),
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
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                CustomText(
                  'N${_formatBalance(overview.balance)}',
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                const SizedBox(height: 18),
                CustomText(
                  overview.accountNumber ?? 'No account number',
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 3),
                CustomText(
                  overview.bankName,
                  color: Colors.white70,
                  fontSize: 12.5.sp,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: overview.accountNumber == null
                ? null
                : () => _showBankDetailsModal(context, overview),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Top Up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBalance(double? balance) {
    if (balance == null) return '****';
    return _balanceFormatter.format(balance);
  }

  static void _showBankDetailsModal(
    BuildContext context,
    WalletOverview overview,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final accountNumber = overview.accountNumber ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: AppTheme.ocean,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                'Top up your wallet',
                                fontWeight: FontWeight.w900,
                                fontSize: 18.sp,
                                color: AppTheme.ink,
                              ),
                              const SizedBox(height: 6),
                              CustomText(
                                'Transfer to this reserved account and your wallet balance will update automatically after confirmation.',
                                fontSize: 13.5.sp,
                                color: Colors.black.withValues(alpha: 0.66),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF4F7FB),
                            foregroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.ocean.withValues(alpha: 0.08),
                            AppTheme.accent.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.ocean.withValues(alpha: 0.10),
                        ),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _DetailRow(
                              label: 'Bank name', value: overview.bankName),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Account number',
                            value: accountNumber,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: accountNumber),
                          );
                          showAppSnackBar(
                            sheetContext,
                            message: 'Account number copied',
                            tone: AppFeedbackTone.success,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.ocean,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text(
                          'Copy account number',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: CustomText(
                        'Use your bank app or transfer code, then send the exact amount you want to add. Wallet top-ups usually reflect shortly after your bank confirms the transfer.',
                        fontSize: 13.sp,
                        color: Colors.black.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                fontSize: 12.2.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 6),
              CustomText(
                value,
                fontSize: 16.2.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ],
          ),
        ),
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
      label: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
          color: selected ? AppTheme.ink : AppTheme.ocean,
        ),
      ),
      selected: selected,
      showCheckmark: selected,
      selectedColor: AppTheme.accent.withValues(alpha: 0.20),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? AppTheme.accent.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.08),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isDebit ? Icons.south_east : Icons.north_east,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  transaction.displayTitle,
                  fontSize: 16.4.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
                const SizedBox(height: 6),
                CustomText(
                  transaction.description,
                  fontSize: 13.6.sp,
                  color: Colors.black.withValues(alpha: 0.66),
                ),
                const SizedBox(height: 6),
                CustomText(
                  date,
                  fontSize: 12.4.sp,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                amount,
                fontSize: 16.6.sp,
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
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: CustomText(
                  transaction.status,
                  fontSize: 12.1.sp,
                  fontWeight: FontWeight.w700,
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
