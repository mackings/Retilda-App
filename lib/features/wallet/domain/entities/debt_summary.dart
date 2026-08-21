class DebtInstallment {
  const DebtInstallment({
    required this.paymentIndex,
    required this.missedPeriod,
    required this.originalAmount,
    required this.lateFeeTotal,
    required this.lateFeePaid,
    required this.lateFeeOutstanding,
    required this.weeksOverdue,
  });

  final int paymentIndex;
  final DateTime missedPeriod;
  final num originalAmount;
  final num lateFeeTotal;
  final num lateFeePaid;
  final num lateFeeOutstanding;
  final int weeksOverdue;
}

class DebtPurchase {
  const DebtPurchase({
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.purchaseDebt,
    required this.installments,
  });

  final String purchaseId;
  final String? productId;
  final String productName;
  final String? productImage;
  final num purchaseDebt;
  final List<DebtInstallment> installments;
}

class DebtSummary {
  const DebtSummary({
    required this.hasDebt,
    required this.totalDebt,
    required this.purchases,
  });

  final bool hasDebt;
  final num totalDebt;
  final List<DebtPurchase> purchases;

  static const empty = DebtSummary(
    hasDebt: false,
    totalDebt: 0,
    purchases: [],
  );
}
