import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../database/firebase_service.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Màn hình Chi tiết sản phẩm (ProductDetailScreen)
/// Chức năng:
/// - Xem ảnh, mô tả, giá và trạng thái kho hàng.
/// - Chọn size và số lượng.
/// - Thêm vào giỏ hàng (CartProvider).
/// - Mua ngay (Đặt hàng trực tiếp - Firestore).
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;      // Số lượng người dùng chọn
  String? _selectedSize;  // Size người dùng chọn
  final FirebaseService _firebaseService = FirebaseService();
  bool _isOrdering = false; // Trạng thái khi nhấn nút "Mua ngay"

  @override
  void initState() {
    super.initState();
    // Mặc định chọn size đầu tiên nếu sản phẩm có danh sách size
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
  }

  /// Logic: Thêm vào giỏ hàng
  /// Dữ liệu sẽ được lưu cục bộ trong CartProvider (Global State)
  void _addToCart() {
    Provider.of<CartProvider>(context, listen: false).addItem(
      widget.product,
      _quantity,
      _selectedSize,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Logic: Mua ngay (Đặt hàng trực tiếp)
  /// Sẽ hiển thị một Bottom Sheet để người dùng nhập thông tin giao hàng
  void _placeOrder() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    // Thử lấy tên mặc định từ Profile nếu đã đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firebaseService.getUserProfile(user.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          nameController.text = data['name'] ?? '';
        }
      }
    }

    if (!mounted) return;

    // Hiển thị khung nhập liệu
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin nhận hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                    );
                    return;
                  }
                  
                  Navigator.pop(ctx);
                  setState(() => _isOrdering = true);
                  try {
                    // Gọi FirebaseService để tạo bản ghi đơn hàng
                    await _firebaseService.placeOrder(
                      widget.product,
                      _quantity,
                      _selectedSize,
                      customerName: nameController.text.trim(),
                      customerPhone: phoneController.text.trim(),
                      customerAddress: addressController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đặt hàng thành công!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context); // Quay về trang chủ
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _isOrdering = false);
                  }
                },
                child: const Text('XÁC NHẬN ĐẶT HÀNG'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tổng hợp tất cả ảnh của sản phẩm
    final List<String> allImages = [widget.product.imageUrl, ...widget.product.imageUrls];
    // Định dạng tiền tệ Việt Nam
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header là một Slider ảnh
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên và Giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        currencyFormat.format(widget.product.price),
                        style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tồn kho
                  Text(
                    'Trạng thái: ${widget.product.stock > 0 ? "Còn hàng (${widget.product.stock})" : "Hết hàng"}',
                    style: TextStyle(color: widget.product.stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 40),
                  
                  // Chọn Size (nếu có)
                  if (widget.product.sizes.isNotEmpty) ...[
                    const Text('Chọn Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: widget.product.sizes.map((size) {
                        final isSelected = _selectedSize == size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSize = size);
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Mô tả
                  const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Chọn số lượng
                  Row(
                    children: [
                      const Text('Số lượng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                                onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null),
                                icon: const Icon(Icons.remove)),
                            Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () => setState(() => _quantity++),
                                icon: const Icon(Icons.add)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Khoảng trống để không bị nút đè lên
                ],
              ),
            ),
          ),
        ],
      ),
      // Thanh công cụ mua hàng ở dưới cùng
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            // Nút Thêm vào giỏ
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
                onPressed: widget.product.stock > 0 ? _addToCart : null,
              ),
            ),
            const SizedBox(width: 16),
            // Nút Mua ngay
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isOrdering || widget.product.stock <= 0) ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isOrdering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.product.stock > 0 ? 'MUA NGAY' : 'HẾT HÀNG'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
