class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}
