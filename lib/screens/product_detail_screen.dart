import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../database/firebase_service.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedSize;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
  }

  void _addToCart() {
    Provider.of<CartProvider>(context, listen: false).addItem(
      widget.product,
      _quantity,
      _selectedSize,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _placeOrder() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    // Thử lấy thông tin cũ từ profile nếu có
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thông tin nhận hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
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
                  const SnackBar(content: Text('Đặt hàng thành công!')),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              } finally {
                if (mounted) setState(() => _isOrdering = false);
              }
            },
            child: const Text('Xác nhận đặt hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kết hợp ảnh chính và các ảnh phụ
    final List<String> allImages = [widget.product.imageUrl, ...widget.product.imageUrls];
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Carousel (Simple PageView) ---
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    allImages[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error)),
                  );
                },
              ),
            ),
            if (allImages.length > 1)
              const Center(child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Text('Vuốt để xem thêm ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)),
              )),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.product.price * _quantity),
                    style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Còn lại trong kho: ${widget.product.stock}',
                      style: TextStyle(fontSize: 16, color: widget.product.stock > 0 ? Colors.green : Colors.red)),
                  
                  // --- Size Selection ---
                  if (widget.product.sizes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Chọn Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: widget.product.sizes.map((size) {
                        return ChoiceChip(
                          label: Text(size),
                          selected: _selectedSize == size,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSize = size);
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.product.description),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Số lượng: ', style: TextStyle(fontSize: 18)),
                      IconButton(
                          onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null),
                          icon: const Icon(Icons.remove)),
                      Text('$_quantity', style: const TextStyle(fontSize: 18)),
                      IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.product.stock > 0 ? _addToCart : null,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Thêm vào giỏ'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_isOrdering || widget.product.stock <= 0) ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: _isOrdering
                              ? const CircularProgressIndicator()
                              : Text(widget.product.stock > 0 ? 'Đặt hàng ngay' : 'Hết hàng'),
                        ),
                      ),
                    ],
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
