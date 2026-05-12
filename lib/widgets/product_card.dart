import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

/// ProductCard: Widget hiển thị tóm tắt thông tin một sản phẩm (dạng thẻ)
/// Thường dùng trong GridView hoặc ListView ở màn hình Trang chủ.
class ProductCard extends StatelessWidget {
  final ProductModel product; // Dữ liệu sản phẩm truyền vào
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Định dạng tiền tệ
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return GestureDetector(
      // Khi nhấn vào thẻ -> Chuyển đến màn hình Chi tiết sản phẩm
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN HÌNH ẢNH ---
            Expanded(
              child: Stack(
                children: [
                  // Ảnh sản phẩm
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      image: DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Hiển thị lớp phủ mờ nếu hết hàng
                  if (product.stock <= 0)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: const Center(
                        child: Text(
                          'HẾT HÀNG',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  // Icon yêu thích (Trang trí)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            // --- PHẦN THÔNG TIN ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Cắt ngắn nếu tên quá dài
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  // Giá sản phẩm
                  Text(
                    currencyFormat.format(product.price),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
