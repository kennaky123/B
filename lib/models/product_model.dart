class ProductModel {
  final String? idString; 
  final String name;
  final double price;
  final String description;
  final String imageUrl; // Ảnh chính
  final List<String> imageUrls; // Danh sách nhiều ảnh
  final List<String> sizes; // Danh sách size (S, M, L, XL...)
  final String status; 
  final int stock; 
  final String category; // Danh mục: Áo, Quần, Phụ kiện, Giày...

  ProductModel({
    this.idString,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    this.sizes = const [],
    this.status = 'Processing',
    this.stock = 100,
    this.category = 'Tất cả',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'sizes': sizes,
      'status': status,
      'stock': stock,
      'category': category,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ProductModel(
      idString: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      status: map['status'] ?? 'Processing',
      stock: map['stock'] ?? 100,
      category: map['category'] ?? 'Tất cả',
    );
  }
}
