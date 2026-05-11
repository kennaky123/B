import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? size;
  final String imageUrl;

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

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(ProductModel product, int quantity, String? size) {
    // Tạo key dựa trên productId và size để phân biệt cùng 1 sản phẩm nhưng khác size
    final key = "${product.idString}_$size";
    
    if (_items.containsKey(key)) {
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
    notifyListeners();
  }

  void removeItem(String productId, String? size) {
    _items.remove("${productId}_$size");
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
