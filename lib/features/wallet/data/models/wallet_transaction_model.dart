import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.senderName,
    required super.amount,
    required super.description,
    required super.transactionType,
    required super.status,
    required super.transactionDate,
    super.paymentMethod,
    super.paymentPlan,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      senderName: json['senderName']?.toString() ?? 'Unknown Sender',
      amount: json['amount'] is num ? json['amount'] as num : 0,
      description: json['description']?.toString() ?? 'No description',
      transactionType: json['transactionType']?.toString() ?? 'Unknown Type',
      status: json['status']?.toString() ?? 'Unknown Status',
      transactionDate: _parseDate(json['paymentDate'] ?? json['createdAt']),
      paymentMethod: json['paymentMethod']?.toString(),
      paymentPlan: json['paymentPlan']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic rawDate) {
    if (rawDate == null) return DateTime.now();
    return DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
  }
}
