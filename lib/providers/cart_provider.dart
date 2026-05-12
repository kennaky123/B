import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// CartItem: Đại diện cho một mục sản phẩm trong giỏ hàng
class CartItem {
  final String id;          // ID duy nhất của mục trong giỏ (thường là timestamp)
  final String productId;   // ID của sản phẩm trong Firestore
  final String name;        // Tên sản phẩm
  final int quantity;       // Số lượng đặt mua
  final double price;       // Giá tại thời điểm cho vào giỏ
  final String? size;       // Kích thước đã chọn
  final String imageUrl;    // Ảnh sản phẩm để hiển thị trong giỏ hàng

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.size,
    required this.imageUrl,
  });
}

/// CartProvider: Quản lý trạng thái giỏ hàng cho toàn bộ ứng dụng
/// Sử dụng ChangeNotifier để thông báo cho các UI liên quan cập nhật khi giỏ hàng thay đổi.
class CartProvider with ChangeNotifier {
  // Danh sách các mục trong giỏ, dùng Map để tìm kiếm nhanh bằng key
  Map<String, CartItem> _items = {};

  // Getter để lấy danh sách sản phẩm (trả về bản sao để đảm bảo tính đóng gói)
  Map<String, CartItem> get items {
    return {..._items};
  }

  // Lấy tổng số loại sản phẩm trong giỏ
  int get itemCount {
    return _items.length;
  }

  // Tính tổng tiền toàn bộ giỏ hàng
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  /// Thêm sản phẩm vào giỏ hàng
  void addItem(ProductModel product, int quantity, String? size) {
    // Tạo key dựa trên productId và size để phân biệt cùng 1 sản phẩm nhưng khác size
    // Ví dụ: Ao_S và Ao_M sẽ là 2 dòng khác nhau trong giỏ hàng.
    final key = "${product.idString}_$size";
    
    if (_items.containsKey(key)) {
      // Nếu đã có sản phẩm này với size này trong giỏ -> Chỉ tăng số lượng
      _items.update(
        key,
        (existingItem) => CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + quantity,
          size: existingItem.size,
          imageUrl: existingItem.imageUrl,
        ),
      );
    } else {
      // Nếu chưa có -> Thêm mới vào Map
      _items.putIfAbsent(
        key,
        () => CartItem(
          id: DateTime.now().toString(),
          productId: product.idString!,
          name: product.name,
          price: product.price,
          quantity: quantity,
          size: size,
          imageUrl: product.imageUrl,
        ),
      );
    }
    // Thông báo cho Flutter biết dữ liệu đã thay đổi để vẽ lại giao diện (Re-build UI)
    notifyListeners();
  }

  /// Xóa một mục khỏi giỏ hàng dựa trên ID sản phẩm và size
  void removeItem(String productId, String? size) {
    _items.remove("${productId}_$size");
    notifyListeners();
  }

  /// Xóa sạch giỏ hàng (Sau khi đặt hàng thành công)
  void clear() {
    _items = {};
    notifyListeners();
  }
}
