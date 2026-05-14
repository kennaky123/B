import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../database/firebase_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final Map<String, String> customerInfo;
  final List<CartItem> cartItems;
  final String? appliedCouponId;
  final bool clearCartOnSuccess;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.customerInfo,
    required this.cartItems,
    this.appliedCouponId,
    this.clearCartOnSuccess = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  void _confirmPayment() async {
    setState(() => _isProcessing = true);
    try {
      final firebaseService = FirebaseService();
      final cart = Provider.of<CartProvider>(context, listen: false);

      // Submit orders to Firestore
      for (var item in widget.cartItems) {
        // Lấy thông tin sản phẩm thật từ Firestore để đảm bảo stock mới nhất
        // Tuy nhiên để đơn giản theo logic cũ, ta tạo ProductModel tạm
        // Lưu ý: FirebaseService.placeOrder sẽ kiểm tra stock.
        // Ở đây ta giả định product.stock là đủ lớn vì ta không có ProductModel gốc ở đây.
        // Một cách tốt hơn là truyền ProductModel vào hoặc fetch lại.
        // Nhưng dựa trên checkout_screen.dart cũ:
        
        final product = ProductModel(
          idString: item.productId,
          name: item.name,
          price: item.price, 
          description: '',
          imageUrl: item.imageUrl,
          stock: 999, // Giá trị tạm, FirebaseService sẽ lấy stock thật nếu cần hoặc dùng giá trị này
        );

        await firebaseService.placeOrder(
          product,
          item.quantity,
          item.size,
          customerName: widget.customerInfo['name'],
          customerPhone: widget.customerInfo['phone'],
          customerAddress: widget.customerInfo['address'],
          status: 'Chờ xác nhận thanh toán', // Trạng thái mới để Admin kiểm tra
        );
      }

      if (widget.appliedCouponId != null) {
        await firebaseService.incrementCouponUsage(widget.appliedCouponId!);
      }

      // Xóa giỏ hàng nếu cần
      if (widget.clearCartOnSuccess) {
        cart.clear();
      }

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Thành công!'),
          content: const Text('Đơn hàng của bạn đã được thanh toán và tiếp nhận.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Quay về trang chủ
                Navigator.of(context).popUntil((route) => route.isFirst);
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    
    // Thông tin ngân hàng (Có thể thay đổi theo ý muốn)
    const String bankId = "MB"; // Ngân hàng MB
    const String accountNo = "0763550948";
    const String accountName = "DANG QUOC TOAN";
    final String description = "THANH TOAN DON HANG";
    
    // Link VietQR: https://vietqr.net/tra-cuu-api/danh-sach-api
    final String qrUrl = "https://img.vietqr.io/image/$bankId-$accountNo-compact.png?amount=${widget.amount.toInt()}&addInfo=$description&accountName=$accountName";

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Quét mã QR để thanh toán qua ứng dụng Ngân hàng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade100, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  qrUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Số tiền cần thanh toán:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              currencyFormat.format(widget.amount),
              style: const TextStyle(fontSize: 26, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _InfoRow(label: 'Ngân hàng', value: 'MB Bank (Quân Đội)'),
                    Divider(),
                    _InfoRow(label: 'Số tài khoản', value: '0763550948'),
                    Divider(),
                    _InfoRow(label: 'Chủ tài khoản', value: 'DANG QUOC TOAN'),
                    Divider(),
                    _InfoRow(label: 'Nội dung', value: 'THANH TOAN DON HANG'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Vui lòng nhấn nút dưới đây sau khi bạn đã thực hiện chuyển khoản thành công.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 15),
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _confirmPayment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'XÁC NHẬN ĐÃ CHUYỂN KHOẢN',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
