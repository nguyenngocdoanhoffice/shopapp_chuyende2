class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final int? categoryId;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    final relatedCategory = map['categories'] as Map<String, dynamic>?;
    final categoryName = relatedCategory?['name'] as String?;

    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: categoryName ?? map['category'] as String? ?? 'Other',
      categoryId: map['category_id'] as int?,
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
      'category_id': categoryId,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}
