class InvoiceListResponse {
  final bool? success;
  final String? message;
  final List<Invoice>? data;

  InvoiceListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<Invoice>.from(
              json['data'].map((item) => Invoice.fromJson(item)))
          : null,
    );
  }
}

class InvoiceCreateResponse {
  final bool? success;
  final String? message;
  final Invoice? data;

  InvoiceCreateResponse({
    this.success,
    this.message,
    this.data,
  });

  factory InvoiceCreateResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceCreateResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? Invoice.fromJson(json['data']) : null,
    );
  }
}

class InvoicePayResponse {
  final bool? success;
  final String? message;
  final String? payLink;

  InvoicePayResponse({
    this.success,
    this.message,
    this.payLink,
  });

  factory InvoicePayResponse.fromJson(Map<String, dynamic> json) {
    return InvoicePayResponse(
      success: json['success'],
      message: json['message'],
      payLink: json['data']?['payLink'],
    );
  }
}

class Invoice {
  final String? id;
  final String? reference;
  final num? amount;
  final String? payLink;
  final String? status;
  final String? createdAt;

  Invoice({
    this.id,
    this.reference,
    this.amount,
    this.payLink,
    this.status,
    this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['invoiceId'] ?? json['_id'] ?? json['id'],
      reference: json['reference'],
      amount: json['amount'],
      payLink: json['payLink'],
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }
}

class OutstandingUserListResponse {
  final bool? success;
  final String? message;
  final List<OutstandingUser>? data;

  OutstandingUserListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory OutstandingUserListResponse.fromJson(Map<String, dynamic> json) {
    return OutstandingUserListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<OutstandingUser>.from(
              json['data'].map((item) => OutstandingUser.fromJson(item)))
          : null,
    );
  }
}

class OutstandingPurchaseListResponse {
  final bool? success;
  final String? message;
  final List<OutstandingPurchase>? data;

  OutstandingPurchaseListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory OutstandingPurchaseListResponse.fromJson(Map<String, dynamic> json) {
    return OutstandingPurchaseListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<OutstandingPurchase>.from(
              json['data'].map((item) => OutstandingPurchase.fromJson(item)))
          : null,
    );
  }
}

class OutstandingUser {
  final InvoiceUser? user;
  final num? totalOutstanding;
  final List<OutstandingPurchase>? purchases;

  OutstandingUser({
    this.user,
    this.totalOutstanding,
    this.purchases,
  });

  factory OutstandingUser.fromJson(Map<String, dynamic> json) {
    return OutstandingUser(
      user: json['user'] != null ? InvoiceUser.fromJson(json['user']) : null,
      totalOutstanding: json['totalOutstanding'],
      purchases: json['purchases'] != null
          ? List<OutstandingPurchase>.from(
              json['purchases'].map((item) => OutstandingPurchase.fromJson(item)))
          : null,
    );
  }
}

class OutstandingPurchase {
  final String? id;
  final String? purchaseType;
  final String? orderStatus;
  final String? deliveryStatus;
  final num? remainingAmount;
  final InvoiceProduct? product;

  OutstandingPurchase({
    this.id,
    this.purchaseType,
    this.orderStatus,
    this.deliveryStatus,
    this.remainingAmount,
    this.product,
  });

  factory OutstandingPurchase.fromJson(Map<String, dynamic> json) {
    return OutstandingPurchase(
      id: json['_id'] ?? json['id'],
      purchaseType: json['purchaseType'],
      orderStatus: json['orderStatus'],
      deliveryStatus: json['deliveryStatus'],
      remainingAmount: json['remainingAmount'],
      product:
          json['product'] != null ? InvoiceProduct.fromJson(json['product']) : null,
    );
  }
}

class InvoiceUser {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;

  InvoiceUser({
    this.id,
    this.fullName,
    this.email,
    this.phone,
  });

  factory InvoiceUser.fromJson(Map<String, dynamic> json) {
    return InvoiceUser(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class InvoiceProduct {
  final String? id;
  final String? name;
  final num? price;
  final List<String>? images;

  InvoiceProduct({
    this.id,
    this.name,
    this.price,
    this.images,
  });

  factory InvoiceProduct.fromJson(Map<String, dynamic> json) {
    return InvoiceProduct(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      price: json['price'],
      images:
          json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }
}
