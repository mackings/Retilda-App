class Content {
  final String senderName;
  final int amount;
  final String description;
  final String transactionType;
  final String status;
  final String transactionDate;
  final String? paymentMethod; // optional for deposits
  final String? paymentPlan; // optional for deposits

  Content({
    required this.senderName,
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.status,
    required this.transactionDate,
    this.paymentMethod,
    this.paymentPlan,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      senderName: json['senderName'] ?? 'Unknown Sender',
      amount: json['amount'] ?? 0,
      description: json['description'] ?? 'No description',
      transactionType: json['transactionType'] ?? 'Unknown Type',
      status: json['status'] ?? 'Unknown Status',
      transactionDate: json['createdAt'] ?? json['paymentDate'] ?? 'Unknown Date',
      paymentMethod: json['paymentMethod'],
      paymentPlan: json['paymentPlan'],
    );
  }
}
