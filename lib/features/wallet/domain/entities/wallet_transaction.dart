class WalletTransaction {
  const WalletTransaction({
    required this.senderName,
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.status,
    required this.transactionDate,
    this.paymentMethod,
    this.paymentPlan,
  });

  final String senderName;
  final num amount;
  final String description;
  final String transactionType;
  final String status;
  final DateTime transactionDate;
  final String? paymentMethod;
  final String? paymentPlan;

  bool get isDebit => transactionType == 'purchase';

  bool get isSuccess => status.toLowerCase() == 'success';

  String get displayTitle {
    if (transactionType == 'purchase') {
      return status == 'settlement' ? 'Product Settlement' : 'Product Purchase';
    }
    return senderName == 'Unknown Sender' ? 'Service charge' : senderName;
  }
}
