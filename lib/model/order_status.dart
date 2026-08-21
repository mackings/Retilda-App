class OrderStatusResponse {
  final bool? success;
  final String? message;
  final OrderStatusData? data;

  OrderStatusResponse({
    this.success,
    this.message,
    this.data,
  });

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null ? OrderStatusData.fromJson(json['data']) : null,
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

class OrderStatusData {
  final String? id;
  final String? orderStatus;
  final String? deliveryStatus;
  final String? paymentPlan;
  final String? userPurchaseRule;
  final String? purchaseFlowVersion;
  final bool? purchaseRuleMismatch;
  final String? recurringPaymentMethod;
  final String? recurringPaymentStatus;
  final Map<String, dynamic>? recurringCard;
  final List<dynamic>? payments;

  OrderStatusData({
    this.id,
    this.orderStatus,
    this.deliveryStatus,
    this.paymentPlan,
    this.userPurchaseRule,
    this.purchaseFlowVersion,
    this.purchaseRuleMismatch,
    this.recurringPaymentMethod,
    this.recurringPaymentStatus,
    this.recurringCard,
    this.payments,
  });

  factory OrderStatusData.fromJson(Map<String, dynamic> json) {
    return OrderStatusData(
      id: json['_id'],
      orderStatus: json['orderStatus'],
      deliveryStatus: json['deliveryStatus'],
      paymentPlan: json['paymentPlan'],
      userPurchaseRule: json['userPurchaseRule']?.toString(),
      purchaseFlowVersion: json['purchaseFlowVersion']?.toString(),
      purchaseRuleMismatch: json['purchaseRuleMismatch'] == true,
      recurringPaymentMethod: json['recurringPaymentMethod']?.toString(),
      recurringPaymentStatus: json['recurringPaymentStatus']?.toString(),
      recurringCard: json['recurringCard'] is Map
          ? Map<String, dynamic>.from(json['recurringCard'])
          : null,
      payments: json['payments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderStatus': orderStatus,
      'deliveryStatus': deliveryStatus,
      'paymentPlan': paymentPlan,
      'userPurchaseRule': userPurchaseRule,
      'purchaseFlowVersion': purchaseFlowVersion,
      'purchaseRuleMismatch': purchaseRuleMismatch,
      'recurringPaymentMethod': recurringPaymentMethod,
      'recurringPaymentStatus': recurringPaymentStatus,
      'recurringCard': recurringCard,
      'payments': payments,
    };
  }
}

class UpdateOrderStatusResponse {
  final bool? success;
  final String? message;
  final OrderStatusData? data;

  UpdateOrderStatusResponse({
    this.success,
    this.message,
    this.data,
  });

  factory UpdateOrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateOrderStatusResponse(
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null ? OrderStatusData.fromJson(json['data']) : null,
    );
  }
}
