import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';

class WalletOverview {
  const WalletOverview({
    required this.balance,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.transactions,
  });

  final double? balance;
  final String? accountNumber;
  final String? accountName;
  final String bankName;
  final List<WalletTransaction> transactions;
}
