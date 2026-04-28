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
    final rawData = json['data'];
    return PurchaseResponse(
      success: _readBool(json['success']),
      message: json['message']?.toString(),
      data: rawData is Map<String, dynamic>
          ? PurchaseData.fromJson(rawData)
          : rawData is List
              ? PurchaseData.fromList(
                  rawData,
                  userPurchaseRule: json['userPurchaseRule']?.toString(),
                )
              : PurchaseData.fromJson(json),
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
  final String? userPurchaseRule;
  final num? totalAmountPaid;
  final num? totalAmountToPay;

  PurchaseData({
    this.purchasesData,
    this.totalPurchases,
    this.userPurchaseRule,
    this.totalAmountPaid,
    this.totalAmountToPay,
  });

  factory PurchaseData.fromList(
    List<dynamic> rawList, {
    String? userPurchaseRule,
  }) {
    return PurchaseData(
      purchasesData: _readPurchaseList(rawList),
      totalPurchases: rawList.length,
      userPurchaseRule: userPurchaseRule,
    );
  }

  factory PurchaseData.fromJson(Map<String, dynamic> json) {
    final rawList = json['purchasesData'] ?? json['purchases'];
    return PurchaseData(
      purchasesData: rawList is List ? _readPurchaseList(rawList) : null,
      totalPurchases: _readInt(json['totalPurchases'] ?? json['count']),
      userPurchaseRule: json['userPurchaseRule']?.toString(),
      totalAmountPaid: _readNum(json['totalAmountPaid']),
      totalAmountToPay: _readNum(json['totalAmountToPay']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasesData': purchasesData != null
          ? List<dynamic>.from(purchasesData!.map((item) => item.toJson()))
          : null,
      'totalPurchases': totalPurchases,
      'userPurchaseRule': userPurchaseRule,
      'totalAmountPaid': totalAmountPaid,
      'totalAmountToPay': totalAmountToPay,
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
  final String? purchaseFlowVersion;
  final bool? purchaseRuleMismatch;
  final num? downPaymentPercent;
  final num? downPaymentAmount;
  final int? numberOfInstallments;
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
  final num? totalPaidForPurchase;
  final List<Payment>? payments;
  final String? createdAt;

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
    this.purchaseFlowVersion,
    this.purchaseRuleMismatch,
    this.downPaymentPercent,
    this.downPaymentAmount,
    this.numberOfInstallments,
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
    this.totalPaidForPurchase,
    this.payments,
    this.createdAt,
  });

  num get resolvedDownPaymentAmount {
    if (isLegacyFlow) return 0;
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
    if (totalPaidForPurchase != null) return totalPaidForPurchase!;
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

  bool get isLegacyFlow =>
      purchaseFlowVersion == 'legacy' ||
      (purchaseFlowVersion == null &&
          purchaseType == null &&
          downPaymentPercent == null &&
          downPaymentAmount == null);

  bool get hasPaidDownPayment {
    final required = resolvedDownPaymentAmount;
    if (required <= 0) return false;
    final paid = totalPaidComputed;
    return paid >= required;
  }

  bool get isDeliveryCompleted =>
      deliveryStatus == 'completed' ||
      (deliveryRequested == true && deliveryPaymentStatus == 'paid');

  bool get hasPendingDeliveryPayment =>
      deliveryPaymentStatus == 'pending' && deliveryRequested != true;

  bool get hasLockedDeliveryFee => isDeliveryCompleted;

  Map<String, dynamic> get deliveryStateSnapshot {
    return {
      'deliveryEligible': duePaymentCompleted == true,
      'deliveryRequirement':
          purchaseType == null ? 'legacy_60_percent' : 'down_payment',
      'deliveryStatus': deliveryStatus,
      'orderStatus': orderStatus,
      'deliveryRequested': deliveryRequested,
      'deliveryRequestedAt': deliveryRequestedAt,
      'deliveryDestination': hasLockedDeliveryFee ? deliveryDestination : null,
      'deliveryQuote': hasLockedDeliveryFee ? deliveryQuote : null,
      'deliveryFeeAmount': hasLockedDeliveryFee ? deliveryFeeAmount : 0,
      'deliveryFeeCurrency': deliveryFeeCurrency,
      'deliveryPaymentStatus': deliveryPaymentStatus,
      'deliveryPaymentReference': deliveryPaymentReference,
      'deliveryPaymentRequestedAt': deliveryPaymentRequestedAt,
      'deliveryPaymentPaidAt': deliveryPaymentPaidAt,
      'deliveryRequestNotifiedAt': deliveryRequestNotifiedAt,
      'amountNeeded':
          duePaymentCompleted == true ? 0 : totalOutstandingComputed,
      'currentAmountPaid': totalPaidComputed,
      'targetAmountPaid': isLegacyFlow
          ? ((basePrice ?? product?.price ?? 0) * 0.6)
          : resolvedDownPaymentAmount,
      'targetPercent': isLegacyFlow ? 0.6 : downPaymentPercent,
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
      id: (json['id'] ?? json['_id'])?.toString(),
      product: Product.fromDynamic(json['product']),
      paymentPlan: json['paymentPlan']?.toString(),
      userId: resolvedUserId,
      userName: resolvedUserName,
      userEmail: resolvedUserEmail,
      userPhone: resolvedUserPhone,
      orderStatus: json['orderStatus']?.toString(),
      purchaseType: json['purchaseType']?.toString(),
      purchaseFlowVersion: json['purchaseFlowVersion']?.toString(),
      purchaseRuleMismatch: _readBool(json['purchaseRuleMismatch']),
      downPaymentPercent: _readNum(json['downPaymentPercent']),
      downPaymentAmount: _readNum(json['downPaymentAmount']),
      numberOfInstallments: _readInt(json['numberOfInstallments']),
      durationMonths: _readInt(json['durationMonths']),
      repaymentFrequency: json['repaymentFrequency']?.toString(),
      totalRepaymentAmount: _readNum(json['totalRepaymentAmount']),
      basePrice: _readNum(json['basePrice']),
      deliveryStatus: json['deliveryStatus']?.toString(),
      duePaymentCompleted: _readBool(json['duePaymentCompleted']),
      deliveryRequested: _readBool(json['deliveryRequested']),
      deliveryRequestedAt: json['deliveryRequestedAt']?.toString(),
      deliveryDestination: json['deliveryDestination'] is Map
          ? Map<String, dynamic>.from(json['deliveryDestination'])
          : null,
      deliveryQuote: json['deliveryQuote'] is Map
          ? Map<String, dynamic>.from(json['deliveryQuote'])
          : null,
      deliveryFeeAmount: _readNum(json['deliveryFeeAmount']),
      deliveryFeeCurrency: json['deliveryFeeCurrency']?.toString(),
      deliveryPaymentStatus: json['deliveryPaymentStatus']?.toString(),
      deliveryPaymentReference: json['deliveryPaymentReference']?.toString(),
      deliveryPaymentRequestedAt:
          json['deliveryPaymentRequestedAt']?.toString(),
      deliveryPaymentPaidAt: json['deliveryPaymentPaidAt']?.toString(),
      deliveryRequestNotifiedAt: json['deliveryRequestNotifiedAt']?.toString(),
      totalAmountToPay: _readNum(json['totalAmountToPay']),
      totalAmountPaid: _readNum(json['totalAmountPaid']),
      totalPaidForPurchase: _readNum(json['totalPaidForPurchase']),
      payments: json['payments'] is List
          ? List<Payment>.from((json['payments'] as List)
              .whereType<Map>()
              .map((item) => Payment.fromJson(Map<String, dynamic>.from(item))))
          : null,
      createdAt: json['createdAt']?.toString(),
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
      'purchaseFlowVersion': purchaseFlowVersion,
      'purchaseRuleMismatch': purchaseRuleMismatch,
      'downPaymentPercent': downPaymentPercent,
      'downPaymentAmount': downPaymentAmount,
      'numberOfInstallments': numberOfInstallments,
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
      'totalPaidForPurchase': totalPaidForPurchase,
      'payments': payments != null
          ? List<dynamic>.from(payments!.map((item) => item.toJson()))
          : null,
      'createdAt': createdAt,
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

  static Product? fromDynamic(dynamic raw) {
    if (raw is Map) {
      return Product.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is String && raw.isNotEmpty) {
      return Product(id: raw);
    }
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? json['_id'])?.toString(),
      name: json['name']?.toString(),
      price: _readInt(json['price']),
      description: json['description']?.toString(),
      images: _readStringList(json['images']),
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
      paymentDate: json['paymentDate']?.toString(),
      nextPaymentDate: json['nextPaymentDate']?.toString(),
      amountPaid: _readNum(json['amountPaid']),
      amountToPay: _readNum(json['amountToPay']),
      lateFeeTotal: _readNum(json['lateFeeTotal']),
      lateFeeAppliedWeeks: _readInt(json['lateFeeAppliedWeeks']),
      status: json['status']?.toString(),
      isDownPayment: _readBool(json['isDownPayment']),
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

List<Purchase> _readPurchaseList(List<dynamic> rawList) {
  return rawList
      .whereType<Map>()
      .map((item) => Purchase.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

num? _readNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '').trim());
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final normalized = value.replaceAll(',', '').trim();
    return int.tryParse(normalized) ?? num.tryParse(normalized)?.toInt();
  }
  return null;
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

List<String>? _readStringList(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? const [] : <String>[trimmed];
  }
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return null;
}
