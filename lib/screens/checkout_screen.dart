import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../database/firebase_service.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';

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
  
  // Quản lý mã giảm giá
  final _couponController = TextEditingController();
  double _discountPercent = 0;
  String? _appliedCouponCode;
  String? _appliedCouponId; // Thêm ID mã

  /// Logic: Kiểm tra mã giảm giá
  void _applyCoupon() async {
    if (_couponController.text.isEmpty) return;
    
    final coupon = await FirebaseService().validateCoupon(_couponController.text.trim());
    if (coupon != null) {
      setState(() {
        _discountPercent = (coupon['discountPercent'] ?? 0).toDouble();
        _appliedCouponCode = coupon['code'];
        _appliedCouponId = coupon['id'];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Áp dụng mã thành công! Giảm $_discountPercent%'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã giảm giá không hợp lệ, đã hết lượt dùng hoặc hết hạn'), backgroundColor: Colors.red),
      );
    }
  }

  /// Logic: Chuyển sang màn hình thanh toán QR
  void _goToPayment() {
    // 1. Kiểm tra xem người dùng đã nhập đủ thông tin chưa
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    double discountFactor = (100 - _discountPercent) / 100;
    double totalAmount = cart.totalAmount * discountFactor;

    // Chuẩn bị danh sách sản phẩm với giá đã giảm (nếu có)
    List<CartItem> discountedItems = cart.items.values.map((item) {
      return CartItem(
        id: item.id,
        productId: item.productId,
        name: item.name,
        quantity: item.quantity,
        price: item.price * discountFactor,
        imageUrl: item.imageUrl,
        size: item.size,
      );
    }).toList();

    // Điều hướng sang màn hình Thanh toán QR
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: totalAmount,
          customerInfo: {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          },
          cartItems: discountedItems,
          appliedCouponId: _appliedCouponId,
          clearCartOnSuccess: true, // Chỉ xóa giỏ hàng khi thanh toán từ Cart
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
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
                  
                  // --- PHẦN NHẬP MÃ GIẢM GIÁ ---
                  const Text('Mã giảm giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã (VD: GIAM20)',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _applyCoupon,
                        child: const Text('ÁP DỤNG'),
                      ),
                    ],
                  ),
                  if (_appliedCouponCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Đã áp dụng mã: $_appliedCouponCode (Giảm $_discountPercent%)',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  
                  const Divider(height: 40),
                  const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Hiển thị danh sách các món đồ sẽ mua
                  ...cart.items.values.map((item) {
                    double itemPrice = item.price;
                    if (_discountPercent > 0) {
                      itemPrice = item.price * (100 - _discountPercent) / 100;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(currencyFormat.format(itemPrice * item.quantity)),
                              if (_discountPercent > 0)
                                Text(
                                  currencyFormat.format(item.price * item.quantity),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  // Tổng tiền thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(cart.totalAmount * (100 - _discountPercent) / 100),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          if (_discountPercent > 0)
                            Text(
                              'Đã giảm: ${currencyFormat.format(cart.totalAmount * _discountPercent / 100)}',
                              style: const TextStyle(color: Colors.green, fontSize: 14),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Nút xác nhận cuối cùng
                  ElevatedButton(
                    onPressed: _goToPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                    ),
                    child: const Text(
                      'TIẾP TỤC THANH TOÁN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
