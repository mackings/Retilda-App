class PurchaseResponse {
  final bool? success;
  final String? message;
  final PurchaseData? data;

  PurchaseResponse({
    this.success,
    this.message,
    this.data,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? PurchaseData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class PurchaseData {
  final List<Purchase>? purchasesData;

  PurchaseData({
    this.purchasesData,
  });

  factory PurchaseData.fromJson(Map<String, dynamic> json) {
    return PurchaseData(
      purchasesData: json['purchasesData'] != null
          ? List<Purchase>.from(
              json['purchasesData'].map((item) => Purchase.fromJson(item)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasesData': purchasesData != null
          ? List<dynamic>.from(purchasesData!.map((item) => item.toJson()))
          : null,
    };
  }
}

class Purchase {
  final String? id;
  final Product? product;
  final String? paymentPlan;
  final String? deliveryStatus;
  final num? totalAmountToPay;
  final num? totalAmountPaid;
  final List<Payment>? payments;

  Purchase({
    this.id,
    this.product,
    this.paymentPlan,
    this.deliveryStatus,
    this.totalAmountToPay,
    this.totalAmountPaid,
    this.payments,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['_id'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      paymentPlan: json['paymentPlan'],
      deliveryStatus: json['deliveryStatus'],
      totalAmountToPay: json['totalAmountToPay'],
      totalAmountPaid: json['totalAmountPaid'],
      payments: json['payments'] != null
          ? List<Payment>.from(
              json['payments'].map((item) => Payment.fromJson(item)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product': product?.toJson(),
      'paymentPlan': paymentPlan,
      'deliveryStatus': deliveryStatus,
      'totalAmountToPay': totalAmountToPay,
      'totalAmountPaid': totalAmountPaid,
      'payments': payments != null
          ? List<dynamic>.from(payments!.map((item) => item.toJson()))
          : null,
    };
  }
}

class Product {
  final String? id;
  final String? name;
  final int? price;
  final String? description;
  final List<String>? images;

  Product({
    this.id,
    this.name,
    this.price,
    this.description,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'images': images,
    };
  }
}

class Payment {
  final String? paymentDate;
  final String? nextPaymentDate;
  final num? amountPaid;
  final num? amountToPay;
  final String? status;

  Payment({
    this.paymentDate,
    this.nextPaymentDate,
    this.amountPaid,
    this.amountToPay,
    this.status,
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
