class CartItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> images;
  final List<String> categories;
  final String? specification;
  final String? brand;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
    required this.categories,
    this.specification,
    this.brand,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'images': images,
        'categories': categories,
        'specification': specification,
        'brand': brand,
      };

  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        description: json['description'],
        images: List<String>.from(json['images']),
        categories: List<String>.from(json['categories']),
        specification: json['specification'],
        brand: json['brand'],
      );
}
