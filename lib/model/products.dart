
class ApiResponse {
  final bool success;
  final String message;
  final List<Product> data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList()
          : [],
    );
  }
}

class Product {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> images;
  final List<String> categories;
  final String specification;
  final String brand;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
    required this.categories,
    required this.specification,
    required this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? "",
      name: json['name'] ?? "",
      price: json['price'] ?? 0,
      description: json['description'] ?? "",
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      categories: json['categories'] != null ? List<String>.from(json['categories']) : [],
      specification: json['specification'] ?? "",
      brand: json['brand'] ?? "",
    );
  }
}


