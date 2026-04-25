class GlancePurchaseSummary {
  final int purchaseCount;
  final double totalAmountPaid;
  final double totalAmountToPay;
  final String? latestPurchaseAt;
  final int completedDeliveryCount;
  final int eligibleForDeliveryCount;

  const GlancePurchaseSummary({
    required this.purchaseCount,
    required this.totalAmountPaid,
    required this.totalAmountToPay,
    required this.latestPurchaseAt,
    required this.completedDeliveryCount,
    required this.eligibleForDeliveryCount,
  });

  factory GlancePurchaseSummary.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return GlancePurchaseSummary(
      purchaseCount: _readInt(data['purchaseCount']),
      totalAmountPaid: _readDouble(data['totalAmountPaid']),
      totalAmountToPay: _readDouble(data['totalAmountToPay']),
      latestPurchaseAt: data['latestPurchaseAt']?.toString(),
      completedDeliveryCount: _readInt(data['completedDeliveryCount']),
      eligibleForDeliveryCount: _readInt(data['eligibleForDeliveryCount']),
    );
  }
}

class GlanceUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? roles;
  final double balance;
  final double referralBonus;
  final bool isActive;
  final String? lastActiveAt;
  final String? accountType;
  final GlancePurchaseSummary purchaseSummary;

  const GlanceUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.roles,
    required this.balance,
    required this.referralBonus,
    required this.isActive,
    required this.lastActiveAt,
    required this.accountType,
    required this.purchaseSummary,
  });

  factory GlanceUser.fromJson(Map<String, dynamic> json) {
    return GlanceUser(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roles: json['roles']?.toString(),
      balance: _readDouble(json['balance']),
      referralBonus: _readDouble(json['referralBonus']),
      isActive: json['isActive'] == true,
      lastActiveAt: json['lastActiveAt']?.toString(),
      accountType: json['accountType']?.toString(),
      purchaseSummary: GlancePurchaseSummary.fromJson(
        json['purchaseSummary'] as Map<String, dynamic>?,
      ),
    );
  }

  String get normalizedFullName => _normalizeName(fullName);

  bool get isExcludedSalesTestAccount =>
      _excludedSalesAccountNames.contains(normalizedFullName) ||
      _excludedSalesAccountEmails.contains(_normalizeName(email));
}

class GlanceProduct {
  final String id;
  final String name;
  final double price;
  final String description;
  final List<String> images;

  const GlanceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  factory GlanceProduct.fromJson(Map<String, dynamic> json) {
    return GlanceProduct(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _readDouble(json['price']),
      description: json['description']?.toString() ?? '',
      images:
          (json['images'] as List?)?.map((item) => item.toString()).toList() ??
              const [],
    );
  }
}

class GlancePayment {
  final String? paymentDate;
  final String? nextPaymentDate;
  final double amountPaid;
  final double amountToPay;
  final String status;

  const GlancePayment({
    this.paymentDate,
    required this.nextPaymentDate,
    required this.amountPaid,
    required this.amountToPay,
    required this.status,
  });

  factory GlancePayment.fromJson(Map<String, dynamic> json) {
    return GlancePayment(
      paymentDate: json['paymentDate']?.toString(),
      nextPaymentDate: json['nextPaymentDate']?.toString(),
      amountPaid: _readDouble(json['amountPaid']),
      amountToPay: _readDouble(json['amountToPay']),
      status: json['status']?.toString() ?? '',
    );
  }
}

class GlancePurchase {
  final String id;
  final GlanceUser? user;
  final GlanceProduct product;
  final String deliveryStatus;
  final String orderStatus;
  final String paymentPlan;
  final String? purchaseType;
  final bool duePaymentCompleted;
  final bool deliveryRequested;
  final String? deliveryRequestedAt;
  final double deliveryFeeAmount;
  final String? deliveryFeeCurrency;
  final String? deliveryPaymentStatus;
  final String? deliveryPaymentReference;
  final String? deliveryPaymentRequestedAt;
  final String? deliveryPaymentPaidAt;
  final List<GlancePayment> payments;
  final double totalAmountPaid;
  final double totalAmountToPay;
  final String? createdAt;

  const GlancePurchase({
    required this.id,
    required this.user,
    required this.product,
    required this.deliveryStatus,
    required this.orderStatus,
    required this.paymentPlan,
    required this.purchaseType,
    required this.duePaymentCompleted,
    required this.deliveryRequested,
    required this.deliveryRequestedAt,
    required this.deliveryFeeAmount,
    required this.deliveryFeeCurrency,
    required this.deliveryPaymentStatus,
    required this.deliveryPaymentReference,
    required this.deliveryPaymentRequestedAt,
    required this.deliveryPaymentPaidAt,
    required this.payments,
    required this.totalAmountPaid,
    required this.totalAmountToPay,
    required this.createdAt,
  });

  double get paidAmount {
    if (totalAmountPaid > 0) {
      return totalAmountPaid;
    }
    return payments.fold<double>(0, (sum, payment) => sum + payment.amountPaid);
  }

  double get amountToPay {
    if (totalAmountToPay > 0) {
      return totalAmountToPay;
    }
    final scheduled = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amountToPay,
    );
    if (scheduled > 0) {
      return scheduled;
    }
    return product.price;
  }

  bool get isCompleted => amountToPay > 0 && paidAmount >= amountToPay;

  factory GlancePurchase.fromJson(
    Map<String, dynamic> json,
    List<GlanceProduct> products,
  ) {
    final productId =
        json['productId']?.toString() ?? json['product']?.toString();
    final product = products.firstWhere(
      (item) => item.id == productId,
      orElse: () => GlanceProduct(
        id: productId ?? '',
        name: 'Unknown Product',
        price: 0,
        description: 'No description',
        images: const [],
      ),
    );

    final userJson = json['userId'];

    return GlancePurchase(
      id: json['_id']?.toString() ?? '',
      user: userJson is Map<String, dynamic>
          ? GlanceUser.fromJson(userJson)
          : null,
      product: product,
      deliveryStatus: json['deliveryStatus']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      paymentPlan: json['paymentPlan']?.toString() ?? '',
      purchaseType: json['purchaseType']?.toString(),
      duePaymentCompleted: json['duePaymentCompleted'] == true,
      deliveryRequested: json['deliveryRequested'] == true,
      deliveryRequestedAt: json['deliveryRequestedAt']?.toString(),
      deliveryFeeAmount: _readDouble(json['deliveryFeeAmount']),
      deliveryFeeCurrency: json['deliveryFeeCurrency']?.toString(),
      deliveryPaymentStatus: json['deliveryPaymentStatus']?.toString(),
      deliveryPaymentReference: json['deliveryPaymentReference']?.toString(),
      deliveryPaymentRequestedAt:
          json['deliveryPaymentRequestedAt']?.toString(),
      deliveryPaymentPaidAt: json['deliveryPaymentPaidAt']?.toString(),
      payments: (json['payments'] as List? ?? const [])
          .map((item) => GlancePayment.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmountPaid: _readDouble(json['totalAmountPaid']),
      totalAmountToPay: _readDouble(json['totalAmountToPay']),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const AdminPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory AdminPagination.fromJson(
    Map<String, dynamic>? json, {
    required String totalItemsKey,
  }) {
    final data = json ?? const <String, dynamic>{};
    return AdminPagination(
      page: _readInt(data['page'], fallback: 1),
      limit: _readInt(data['limit'], fallback: 20),
      totalItems: _readInt(data[totalItemsKey]),
      totalPages: _readInt(data['totalPages'], fallback: 1),
      hasNextPage: data['hasNextPage'] == true,
      hasPreviousPage: data['hasPreviousPage'] == true,
    );
  }
}

class GlanceUsersPage {
  final List<GlanceUser> users;
  final AdminPagination pagination;
  final String search;

  const GlanceUsersPage({
    required this.users,
    required this.pagination,
    required this.search,
  });
}

class GlancePurchasesSummary {
  final int totalPurchases;
  final double totalAmountPaid;
  final double totalAmountToPay;
  final int completedDeliveryCount;

  const GlancePurchasesSummary({
    required this.totalPurchases,
    required this.totalAmountPaid,
    required this.totalAmountToPay,
    required this.completedDeliveryCount,
  });

  factory GlancePurchasesSummary.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return GlancePurchasesSummary(
      totalPurchases: _readInt(data['totalPurchases']),
      totalAmountPaid: _readDouble(data['totalAmountPaid']),
      totalAmountToPay: _readDouble(data['totalAmountToPay']),
      completedDeliveryCount: _readInt(data['completedDeliveryCount']),
    );
  }
}

class GlanceUserPurchasesPage {
  final GlanceUser user;
  final List<GlancePurchase> purchases;
  final GlancePurchasesSummary summary;
  final AdminPagination pagination;

  const GlanceUserPurchasesPage({
    required this.user,
    required this.purchases,
    required this.summary,
    required this.pagination,
  });
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _normalizeName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

const Set<String> _excludedSalesAccountNames = {
  'mackingsley',
  'matt junior',
  'alan',
  'alan matt',
  'alan martineli',
  'alan martinelli',
};

const Set<String> _excludedSalesAccountEmails = {
  'alani@gmail.com',
  'alan2@gmail.com',
  'alan4@gmail.com',
};
