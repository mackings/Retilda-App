class Payment {
  final String? paymentDate; // Nullable
  final String? nextPaymentDate; // Nullable
  final double amountPaid;
  final double amountToPay;
  final String status;

  Payment({
    this.paymentDate,
    this.nextPaymentDate,
    required this.amountPaid,
    required this.amountToPay,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentDate: json['paymentDate'],
      nextPaymentDate: json['nextPaymentDate'],
      amountPaid: json['amountPaid']?.toDouble() ?? 0.0, // Safely handle null
      amountToPay: json['amountToPay']?.toDouble() ?? 0.0, // Safely handle null
      status: json['status'] ?? '', // Default to empty string if null
    );
  }
}

class Product {
  final String id;
  final String name;

  Product({required this.id, required this.name});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '', // Default to empty string if null
      name: json['name'] ?? '', // Default to empty string if null
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '', // Default to empty string if null
      fullName: json['fullName'] ?? '', // Default to empty string if null
      email: json['email'] ?? '', // Default to empty string if null
      phone: json['phone'] ?? '', // Default to empty string if null
    );
  }
}

class DuePayment {
  final String id;
  final User? user; // User can be null
  final Product product;
  final String deliveryStatus;
  final bool duePaymentCompleted;
  final bool adminNotified;
  final String paymentPlan;
  final List<Payment> payments;

  DuePayment({
    required this.id,
    this.user,
    required this.product,
    required this.deliveryStatus,
    required this.duePaymentCompleted,
    required this.adminNotified,
    required this.paymentPlan,
    required this.payments,
  });

  factory DuePayment.fromJson(Map<String, dynamic> json) {
    return DuePayment(
      id: json['_id'] ?? '', // Default to empty string if null
      user: json['userId'] != null ? User.fromJson(json['userId']) : null,
      product: Product.fromJson(json['product'] ?? {}),
      deliveryStatus: json['deliveryStatus'] ?? '', // Default to empty string if null
      duePaymentCompleted: json['duePaymentCompleted'] ?? false, // Default to false if null
      adminNotified: json['adminNotified'] ?? false, // Default to false if null
      paymentPlan: json['paymentPlan'] ?? '', // Default to empty string if null
      payments: (json['payments'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
    );
  }
}

class DuePaymentResponse {
  final bool success;
  final String message;
  final List<DuePayment> data;

  DuePaymentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DuePaymentResponse.fromJson(Map<String, dynamic> json) {
    return DuePaymentResponse(
      success: json['success'] ?? false, // Default to false if null
      message: json['message'] ?? '', // Default to empty string if null
      data: (json['data'] as List)
          .map((duePayment) => DuePayment.fromJson(duePayment))
          .toList(),
    );
  }
}
