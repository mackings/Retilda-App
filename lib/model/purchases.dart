class PurchaseResponse {
  final bool success;
  final String message;
  final PurchaseData data;

  PurchaseResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      success: json['success'],
      message: json['message'],
      data: PurchaseData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class PurchaseData {
  final List<Purchase> purchasesData;
  final num totalAmountPaid;
  final num totalAmountToPay;

  PurchaseData({
    required this.purchasesData,
    required this.totalAmountPaid,
    required this.totalAmountToPay,
  });

  factory PurchaseData.fromJson(Map<String, dynamic> json) {
    return PurchaseData(
      purchasesData: List<Purchase>.from(json['purchasesData'].map((item) => Purchase.fromJson(item))),
      totalAmountPaid: json['totalAmountPaid'],
      totalAmountToPay: json['totalAmountToPay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasesData': List<dynamic>.from(purchasesData.map((item) => item.toJson())),
      'totalAmountPaid': totalAmountPaid,
      'totalAmountToPay': totalAmountToPay,
    };
  }
}

class Purchase {
  final String id;
  final Product product;
  final String paymentPlan;
  final String deliveryStatus;
  final num totalAmountToPay;
  final num totalPaidForPurchase;
  final List<Payment> payments;

  Purchase({
    required this.id,
    required this.product,
    required this.paymentPlan,
    required this.deliveryStatus,
    required this.totalAmountToPay,
    required this.totalPaidForPurchase,
    required this.payments,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['_id'],
      product: Product.fromJson(json['product']),
      paymentPlan: json['paymentPlan'],
      deliveryStatus: json['deliveryStatus'],
      totalAmountToPay: json['totalAmountToPay'],
      totalPaidForPurchase: json['totalPaidForPurchase'],
      payments: List<Payment>.from(json['payments'].map((item) => Payment.fromJson(item))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product': product.toJson(),
      'paymentPlan': paymentPlan,
      'deliveryStatus': deliveryStatus,
      'totalAmountToPay': totalAmountToPay,
      'totalPaidForPurchase': totalPaidForPurchase,
      'payments': List<dynamic>.from(payments.map((item) => item.toJson())),
    };
  }
}

class Product {
  final String id;
  final String name;
  final int price;
  final String description;
  final String images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      images: json['images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'description': description,
      'images': images,
    };
  }
}

class Payment {
  final String paymentDate;
  final String nextPaymentDate;
  final num amountPaid;
  final num amountToPay;
  final String status;

  Payment({
    required this.paymentDate,
    required this.nextPaymentDate,
    required this.amountPaid,
    required this.amountToPay,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentDate: json['paymentDate'],
      nextPaymentDate: json['nextPaymentDate'],
      amountPaid: json['amountPaid'],
      amountToPay: json['amountToPay'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDate': paymentDate,
      'nextPaymentDate': nextPaymentDate,
      'amountPaid': amountPaid,
      'amountToPay': amountToPay,
      'status': status,
    };
  }
}
