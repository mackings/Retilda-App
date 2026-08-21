import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';

class DebtInstallmentModel extends DebtInstallment {
  const DebtInstallmentModel({
    required super.paymentIndex,
    required super.missedPeriod,
    required super.originalAmount,
    required super.lateFeeTotal,
    required super.lateFeePaid,
    required super.lateFeeOutstanding,
    required super.weeksOverdue,
  });

  factory DebtInstallmentModel.fromJson(Map<String, dynamic> json) {
    return DebtInstallmentModel(
      paymentIndex: _readInt(json['paymentIndex']),
      missedPeriod:
          DateTime.tryParse(json['missedPeriod']?.toString() ?? '') ??
              DateTime.now(),
      originalAmount: _readNum(json['originalAmount']),
      lateFeeTotal: _readNum(json['lateFeeTotal']),
      lateFeePaid: _readNum(json['lateFeePaid']),
      lateFeeOutstanding: _readNum(json['lateFeeOutstanding']),
      weeksOverdue: _readInt(json['weeksOverdue']),
    );
  }
}

class DebtPurchaseModel extends DebtPurchase {
  const DebtPurchaseModel({
    required super.purchaseId,
    required super.productId,
    required super.productName,
    required super.productImage,
    required super.purchaseDebt,
    required super.installments,
  });

  factory DebtPurchaseModel.fromJson(Map<String, dynamic> json) {
    final rawInstallments = json['installments'];
    return DebtPurchaseModel(
      purchaseId: json['purchaseId']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ?? 'Product',
      productImage: json['productImage']?.toString(),
      purchaseDebt: _readNum(json['purchaseDebt']),
      installments: rawInstallments is List
          ? rawInstallments
              .whereType<Map<String, dynamic>>()
              .map(DebtInstallmentModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class DebtSummaryModel extends DebtSummary {
  const DebtSummaryModel({
    required super.hasDebt,
    required super.totalDebt,
    required super.purchases,
  });

  factory DebtSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawPurchases = json['purchases'];
    return DebtSummaryModel(
      hasDebt: json['hasDebt'] == true,
      totalDebt: _readNum(json['totalDebt']),
      purchases: rawPurchases is List
          ? rawPurchases
              .whereType<Map<String, dynamic>>()
              .map(DebtPurchaseModel.fromJson)
              .toList()
          : const [],
    );
  }
}

num _readNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
