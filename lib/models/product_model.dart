/// ProductModel: Đại diện cho cấu trúc dữ liệu của một Sản phẩm
class ProductModel {
  final String? idString;     // ID của tài liệu trên Firestore (Document ID)
  final String name;          // Tên sản phẩm
  final double price;         // Giá bán
  final String description;   // Mô tả chi tiết
  final String imageUrl;      // Đường dẫn ảnh đại diện chính
  final List<String> imageUrls; // Danh sách các ảnh bổ sung (Carousel)
  final List<String> sizes;    // Các kích thước có sẵn (S, M, L, XL...)
  final String status;         // Trạng thái (Ví dụ: 'Active', 'Processing')
  final int stock;             // Số lượng còn lại trong kho
  final String category;       // Danh mục sản phẩm (Áo, Quần, Phụ kiện...)

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

  /// Chuyển đổi đối tượng ProductModel thành Map để lưu lên Firestore
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

  /// Khởi tạo đối tượng ProductModel từ dữ liệu tải về từ Firestore (Map)
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
