import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../database/firebase_service.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

/// Màn hình Thanh toán (CheckoutScreen)
/// Chức năng:
/// - Nhập thông tin người nhận (Tên, SĐT, Địa chỉ).
/// - Xem lại tóm tắt đơn hàng và tổng tiền.
/// - Xác nhận đặt toàn bộ sản phẩm trong giỏ hàng lên Firestore.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Các bộ điều khiển nhập liệu thông tin giao hàng
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;

  /// Logic: Gửi đơn hàng
  void _submitOrder() async {
    // 1. Kiểm tra xem người dùng đã nhập đủ thông tin chưa
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final firebaseService = FirebaseService();

    setState(() => _isLoading = true);

    try {
      // 2. Duyệt qua từng sản phẩm trong giỏ hàng để tạo đơn hàng trên Firestore
      for (var item in cart.items.values) {
        // Tạo một ProductModel tạm thời (vì placeOrder yêu cầu model này để trừ kho)
        final product = ProductModel(
          idString: item.productId,
          name: item.name,
          price: item.price,
          description: '',
          imageUrl: item.imageUrl,
          stock: 999, // Giả định kho đủ hàng
        );
        
        // Gọi hàm placeOrder trong FirebaseService
        await firebaseService.placeOrder(
          product, 
          item.quantity, 
          item.size,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          customerAddress: _addressController.text.trim(),
        );
      }

      // 3. Sau khi đặt thành công, làm trống giỏ hàng
      cart.clear();
      if (!mounted) return;
      
      // Hiển thị thông báo thành công
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thành công!'),
          content: const Text('Đơn hàng của bạn đã được tiếp nhận.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng Dialog
                Navigator.of(context).pop(); // Quay về màn hình Giỏ hàng (hoặc trang chủ)
              },
              child: const Text('Đồng ý'),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                  ),
                  const Divider(height: 40),
                  const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Hiển thị danh sách các món đồ sẽ mua
                  ...cart.items.values.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.name} x${item.quantity}'),
                        Text(currencyFormat.format(item.price * item.quantity)),
                      ],
                    ),
                  )),
                  const Divider(),
                  // Tổng tiền thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(cart.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Nút xác nhận cuối cùng
                  ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('XÁC NHẬN ĐẶT HÀNG'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
