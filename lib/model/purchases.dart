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
  final int? totalPurchases;

  PurchaseData({
    this.purchasesData,
    this.totalPurchases,
  });

  factory PurchaseData.fromJson(Map<String, dynamic> json) {
    final rawList = json['purchasesData'] ?? json['purchases'];
    return PurchaseData(
      purchasesData: rawList != null
          ? List<Purchase>.from(
              (rawList as List).map((item) => Purchase.fromJson(item)))
          : null,
      totalPurchases: json['totalPurchases'] ?? json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasesData': purchasesData != null
          ? List<dynamic>.from(purchasesData!.map((item) => item.toJson()))
          : null,
      'totalPurchases': totalPurchases,
    };
  }
}

class Purchase {
  final String? id;
  final Product? product;
  final String? paymentPlan;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? orderStatus;
  final String? purchaseType;
  final num? downPaymentPercent;
  final num? downPaymentAmount;
  final int? durationMonths;
  final String? repaymentFrequency;
  final num? totalRepaymentAmount;
  final num? basePrice;
  final String? deliveryStatus;
  final bool? duePaymentCompleted;
  final bool? deliveryRequested;
  final String? deliveryRequestedAt;
  final Map<String, dynamic>? deliveryDestination;
  final Map<String, dynamic>? deliveryQuote;
  final num? deliveryFeeAmount;
  final String? deliveryFeeCurrency;
  final String? deliveryPaymentStatus;
  final String? deliveryPaymentReference;
  final String? deliveryPaymentRequestedAt;
  final String? deliveryPaymentPaidAt;
  final String? deliveryRequestNotifiedAt;
  final num? totalAmountToPay;
  final num? totalAmountPaid;
  final List<Payment>? payments;

  Purchase({
    this.id,
    this.product,
    this.paymentPlan,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.orderStatus,
    this.purchaseType,
    this.downPaymentPercent,
    this.downPaymentAmount,
    this.durationMonths,
    this.repaymentFrequency,
    this.totalRepaymentAmount,
    this.basePrice,
    this.deliveryStatus,
    this.duePaymentCompleted,
    this.deliveryRequested,
    this.deliveryRequestedAt,
    this.deliveryDestination,
    this.deliveryQuote,
    this.deliveryFeeAmount,
    this.deliveryFeeCurrency,
    this.deliveryPaymentStatus,
    this.deliveryPaymentReference,
    this.deliveryPaymentRequestedAt,
    this.deliveryPaymentPaidAt,
    this.deliveryRequestNotifiedAt,
    this.totalAmountToPay,
    this.totalAmountPaid,
    this.payments,
  });

  num get resolvedDownPaymentAmount {
    if (downPaymentAmount != null) return downPaymentAmount!;
    final price = basePrice ?? product?.price;
    if (downPaymentPercent != null && price != null) {
      return (downPaymentPercent! * price);
    }
    if (purchaseType == 'down_40' && price != null) {
      return price * 0.4;
    }
    if (purchaseType == 'down_50' && price != null) {
      return price * 0.5;
    }
    return 0;
  }

  num get totalPaidComputed {
    if (totalAmountPaid != null) return totalAmountPaid!;
    if (payments == null || payments!.isEmpty) return 0;
    return payments!
        .map((payment) => payment.amountPaid ?? 0)
        .fold<num>(0, (sum, value) => sum + value);
  }

  num get totalToPayComputed {
    if (totalAmountToPay != null) return totalAmountToPay!;
    if ((purchaseType == 'down_40' || purchaseType == 'down_50') &&
        totalRepaymentAmount != null) {
      return resolvedDownPaymentAmount + totalRepaymentAmount!;
    }
    if (totalRepaymentAmount != null) return totalRepaymentAmount!;
    if (basePrice != null) return basePrice!;
    if (product?.price != null) return product!.price!;
    return 0;
  }

  num get totalOutstandingComputed {
    final total = totalToPayComputed;
    final paid = totalPaidComputed;
    if (total > 0) {
      return (total - paid).clamp(0, total);
    }
    if (payments != null && payments!.isNotEmpty) {
      return payments!
          .map((payment) => payment.outstandingAmount)
          .fold<num>(0, (sum, value) => sum + value);
    }
    return 0;
  }

  bool get isNewDownPaymentPlan =>
      purchaseType == 'down_40' || purchaseType == 'down_50';

  bool get hasPaidDownPayment {
    final required = resolvedDownPaymentAmount;
    if (required <= 0) return false;
    final paid = totalPaidComputed;
    return paid >= required;
  }

  bool get isDeliveryCompleted =>
      deliveryRequested == true || deliveryPaymentStatus == 'paid';

  bool get hasPendingDeliveryPayment =>
      deliveryPaymentStatus == 'pending' && deliveryRequested != true;

  Map<String, dynamic> get deliveryStateSnapshot {
    return {
      'deliveryEligible': duePaymentCompleted == true,
      'deliveryRequirement':
          purchaseType == null ? 'legacy_60_percent' : 'down_payment',
      'deliveryStatus': deliveryStatus,
      'orderStatus': orderStatus,
      'deliveryRequested': deliveryRequested,
      'deliveryRequestedAt': deliveryRequestedAt,
      'deliveryDestination': deliveryDestination,
      'deliveryQuote': deliveryQuote,
      'deliveryFeeAmount': deliveryFeeAmount,
      'deliveryFeeCurrency': deliveryFeeCurrency,
      'deliveryPaymentStatus': deliveryPaymentStatus,
      'deliveryPaymentReference': deliveryPaymentReference,
      'deliveryPaymentRequestedAt': deliveryPaymentRequestedAt,
      'deliveryPaymentPaidAt': deliveryPaymentPaidAt,
      'deliveryRequestNotifiedAt': deliveryRequestNotifiedAt,
      'amountNeeded':
          duePaymentCompleted == true ? 0 : totalOutstandingComputed,
      'currentAmountPaid': totalPaidComputed,
      'targetAmountPaid': resolvedDownPaymentAmount,
      'targetPercent': downPaymentPercent,
      if (product?.id != null) 'productId': product!.id,
      if (product?.name != null) 'productName': product!.name,
      'purchaseId': id,
      'basePrice': basePrice ?? product?.price,
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'] ?? json['user'];
    String? resolvedUserId;
    String? resolvedUserName;
    String? resolvedUserEmail;
    String? resolvedUserPhone;
    if (rawUser is String) {
      resolvedUserId = rawUser;
    } else if (rawUser is Map) {
      resolvedUserId = rawUser['_id'] ?? rawUser['id'];
      resolvedUserName = rawUser['fullName'];
      resolvedUserEmail = rawUser['email'];
      resolvedUserPhone = rawUser['phone'];
    }

    return Purchase(
      id: json['id'] ?? json['_id'],
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
      paymentPlan: json['paymentPlan'],
      userId: resolvedUserId,
      userName: resolvedUserName,
      userEmail: resolvedUserEmail,
      userPhone: resolvedUserPhone,
      orderStatus: json['orderStatus'],
      purchaseType: json['purchaseType'],
      downPaymentPercent: json['downPaymentPercent'],
      downPaymentAmount: json['downPaymentAmount'],
      durationMonths: json['durationMonths'],
      repaymentFrequency: json['repaymentFrequency'],
      totalRepaymentAmount: json['totalRepaymentAmount'],
      basePrice: json['basePrice'],
      deliveryStatus: json['deliveryStatus'],
      duePaymentCompleted: json['duePaymentCompleted'],
      deliveryRequested: json['deliveryRequested'],
      deliveryRequestedAt: json['deliveryRequestedAt'],
      deliveryDestination: json['deliveryDestination'] is Map
          ? Map<String, dynamic>.from(json['deliveryDestination'])
          : null,
      deliveryQuote: json['deliveryQuote'] is Map
          ? Map<String, dynamic>.from(json['deliveryQuote'])
          : null,
      deliveryFeeAmount: json['deliveryFeeAmount'],
      deliveryFeeCurrency: json['deliveryFeeCurrency'],
      deliveryPaymentStatus: json['deliveryPaymentStatus'],
      deliveryPaymentReference: json['deliveryPaymentReference'],
      deliveryPaymentRequestedAt: json['deliveryPaymentRequestedAt'],
      deliveryPaymentPaidAt: json['deliveryPaymentPaidAt'],
      deliveryRequestNotifiedAt: json['deliveryRequestNotifiedAt'],
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
      'id': id,
      'product': product?.toJson(),
      'paymentPlan': paymentPlan,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'orderStatus': orderStatus,
      'purchaseType': purchaseType,
      'downPaymentPercent': downPaymentPercent,
      'downPaymentAmount': downPaymentAmount,
      'durationMonths': durationMonths,
      'repaymentFrequency': repaymentFrequency,
      'totalRepaymentAmount': totalRepaymentAmount,
      'basePrice': basePrice,
      'deliveryStatus': deliveryStatus,
      'duePaymentCompleted': duePaymentCompleted,
      'deliveryRequested': deliveryRequested,
      'deliveryRequestedAt': deliveryRequestedAt,
      'deliveryDestination': deliveryDestination,
      'deliveryQuote': deliveryQuote,
      'deliveryFeeAmount': deliveryFeeAmount,
      'deliveryFeeCurrency': deliveryFeeCurrency,
      'deliveryPaymentStatus': deliveryPaymentStatus,
      'deliveryPaymentReference': deliveryPaymentReference,
      'deliveryPaymentRequestedAt': deliveryPaymentRequestedAt,
      'deliveryPaymentPaidAt': deliveryPaymentPaidAt,
      'deliveryRequestNotifiedAt': deliveryRequestNotifiedAt,
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
      id: json['id'] ?? json['_id'],
      name: json['name'],
      price:
          json['price'] is num ? (json['price'] as num).toInt() : json['price'],
      description: json['description'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
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
  final num? lateFeeTotal;
  final int? lateFeeAppliedWeeks;
  final String? status;
  final bool? isDownPayment;

  Payment({
    this.paymentDate,
    this.nextPaymentDate,
    this.amountPaid,
    this.amountToPay,
    this.lateFeeTotal,
    this.lateFeeAppliedWeeks,
    this.status,
    this.isDownPayment,
  });

  num get outstandingAmount {
    final target = amountToPay ?? 0;
    final paid = amountPaid ?? 0;
    return (target - paid).clamp(0, target);
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentDate: json['paymentDate'],
      nextPaymentDate: json['nextPaymentDate'],
      amountPaid: json['amountPaid'],
      amountToPay: json['amountToPay'],
      lateFeeTotal: json['lateFeeTotal'],
      lateFeeAppliedWeeks: json['lateFeeAppliedWeeks'],
      status: json['status'],
      isDownPayment: json['isDownPayment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDate': paymentDate,
      'nextPaymentDate': nextPaymentDate,
      'amountPaid': amountPaid,
      'amountToPay': amountToPay,
      'lateFeeTotal': lateFeeTotal,
      'lateFeeAppliedWeeks': lateFeeAppliedWeeks,
      'status': status,
      'isDownPayment': isDownPayment,
    };
  }
}
