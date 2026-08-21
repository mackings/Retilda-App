class MissingWeightItem {
  const MissingWeightItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.brand,
    required this.availableStock,
    required this.categories,
    required this.deliveryWeightKg,
    required this.activePurchaseCount,
  });

  final String productId;
  final String name;
  final num price;
  final String brand;
  final int availableStock;
  final List<String> categories;
  final num deliveryWeightKg;
  final int activePurchaseCount;

  factory MissingWeightItem.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    return MissingWeightItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      price: json['price'] is num ? json['price'] as num : 0,
      brand: json['brand']?.toString() ?? '',
      availableStock: json['availableStock'] is num
          ? (json['availableStock'] as num).toInt()
          : 0,
      categories: rawCategories is List
          ? rawCategories.map((e) => e.toString()).toList()
          : const [],
      deliveryWeightKg:
          json['deliveryWeightKg'] is num ? json['deliveryWeightKg'] as num : 0,
      activePurchaseCount: json['activePurchaseCount'] is num
          ? (json['activePurchaseCount'] as num).toInt()
          : 0,
    );
  }
}

class MissingWeightCategory {
  const MissingWeightCategory({
    required this.category,
    required this.count,
    required this.items,
  });

  final String category;
  final int count;
  final List<MissingWeightItem> items;

  factory MissingWeightCategory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MissingWeightCategory(
      category: json['category']?.toString() ?? 'Uncategorized',
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(MissingWeightItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class MissingWeightSummary {
  const MissingWeightSummary({
    required this.totalCount,
    required this.categories,
  });

  final int totalCount;
  final List<MissingWeightCategory> categories;

  static const empty = MissingWeightSummary(totalCount: 0, categories: []);

  factory MissingWeightSummary.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    return MissingWeightSummary(
      totalCount:
          json['totalCount'] is num ? (json['totalCount'] as num).toInt() : 0,
      categories: rawCategories is List
          ? rawCategories
              .whereType<Map<String, dynamic>>()
              .map(MissingWeightCategory.fromJson)
              .toList()
          : const [],
    );
  }
}
