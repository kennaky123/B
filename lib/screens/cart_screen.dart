import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';

/// Màn hình Giỏ hàng (CartScreen)
/// Chức năng:
/// - Liệt kê các sản phẩm người dùng đã thêm vào giỏ.
/// - Hiển thị tổng tiền tạm tính.
/// - Cho phép xóa sản phẩm (nhấn giữ).
/// - Nút điều hướng tới màn hình Thanh toán.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Truy cập CartProvider để lấy dữ liệu giỏ hàng hiện tại
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng của bạn')),
      body: Column(
        children: [
          // Thẻ hiển thị Tổng tiền và nút Thanh toán
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  // Hiển thị số tiền bằng Chip
                  Chip(
                    label: Text(
                      currencyFormat.format(cart.totalAmount),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  // Nút chuyển sang màn hình Thanh toán
                  TextButton(
                    onPressed: cart.totalAmount <= 0
                        ? null // Vô hiệu hóa nếu giỏ hàng trống
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                            );
                          },
                    child: const Text('THANH TOÁN'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Danh sách các mặt hàng trong giỏ
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Giỏ hàng của bạn đang trống'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: Image.network(
                              item.imageUrl, 
                              width: 50,
                              errorBuilder: (c, e, s) => const Icon(Icons.shopping_bag),
                            ),
                            title: Text(item.name),
                            subtitle: Text('Giá: ${currencyFormat.format(item.price)}\nSize: ${item.size ?? "N/A"}'),
                            trailing: Text('x ${item.quantity}'),
                            onLongPress: () {
                              // Nhấn giữ để xóa sản phẩm khỏi giỏ hàng
                              cart.removeItem(item.productId, item.size);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
