class GlanceUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  GlanceUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory GlanceUser.fromJson(Map<String, dynamic> json) {
    return GlanceUser(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class GlanceProduct {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> images;

  GlanceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  factory GlanceProduct.fromJson(Map<String, dynamic> json) {
    return GlanceProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class GlancePayment {
  final String? paymentDate;
  final String nextPaymentDate;
  final int amountPaid;
  final int amountToPay;
  final String status;

  GlancePayment({
    this.paymentDate,
    required this.nextPaymentDate,
    required this.amountPaid,
    required this.amountToPay,
    required this.status,
  });

  factory GlancePayment.fromJson(Map<String, dynamic> json) {
    return GlancePayment(
      paymentDate: json['paymentDate'],
      nextPaymentDate: json['nextPaymentDate'] ?? '',
      amountPaid: json['amountPaid'] ?? 0,
      amountToPay: json['amountToPay'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}

class GlancePurchase {
  final String id;
  final GlanceUser user;
  final GlanceProduct product;
  final String deliveryStatus;
  final String paymentPlan;
  final List<GlancePayment> payments;

  GlancePurchase({
    required this.id,
    required this.user,
    required this.product,
    required this.deliveryStatus,
    required this.paymentPlan,
    required this.payments,
  });

  factory GlancePurchase.fromJson(Map<String, dynamic> json, List<GlanceProduct> products) {
    final product = products.firstWhere(
      (p) => p.id == json['product'],
      orElse: () => GlanceProduct(
        id: json['product'] ?? '',
        name: "Unknown Product",
        price: 0,
        description: "No description",
        images: [],
      ),
    );

    return GlancePurchase(
      id: json['_id'] ?? '',
      user: GlanceUser.fromJson(json['userId']),
      product: product,
      deliveryStatus: json['deliveryStatus'] ?? '',
      paymentPlan: json['paymentPlan'] ?? '',
      payments: (json['payments'] as List? ?? [])
          .map((p) => GlancePayment.fromJson(p))
          .toList(),
    );
  }
}
