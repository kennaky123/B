import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../database/firebase_service.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Hiển thị Form để người dùng viết đánh giá
  void _showReviewForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')));
      return;
    }

    final commentController = TextEditingController();
    double userRating = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đánh giá của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => userRating = rating,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Bình luận', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (commentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập bình luận')));
                    return;
                  }
                  
                  // Lấy thông tin user hiện tại
                  final doc = await _firebaseService.getUserProfile(user.uid);
                  final name = doc.exists ? (doc.get('name') ?? 'Khách hàng') : 'Khách hàng';
                  final img = doc.exists ? doc.get('imageUrl') : null;

                  await _firebaseService.addReview(
                    widget.product.idString!,
                    user.uid,
                    name,
                    img,
                    commentController.text.trim(),
                    userRating,
                  );

                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi đánh giá! Vui lòng chờ Admin duyệt.'), backgroundColor: Colors.blue),
                  );
                },
                child: const Text('GỬI ĐÁNH GIÁ'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
    
    // Quản lý mã giảm giá trong Mua ngay
    final couponController = TextEditingController();
    double discountPercent = 0;
    String? appliedCouponCode;
    String? appliedCouponId; // Thêm ID mã

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
      builder: (ctx) => StatefulBuilder( // Dùng StatefulBuilder để cập nhật giá khi áp mã
        builder: (context, setModalState) {
          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
          double currentPrice = widget.product.price * _quantity;
          double finalPrice = currentPrice * (100 - discountPercent) / 100;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
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
                  
                  // --- Ô NHẬP MÃ GIẢM GIÁ ---
                  const Text('Mã giảm giá', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: couponController,
                          decoration: const InputDecoration(hintText: 'Nhập mã', border: OutlineInputBorder()),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final coupon = await _firebaseService.validateCoupon(couponController.text.trim());
                          if (coupon != null) {
                            setModalState(() {
                              discountPercent = (coupon['discountPercent'] ?? 0).toDouble();
                              appliedCouponCode = coupon['code'];
                              appliedCouponId = coupon['id'];
                            });
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mã không hợp lệ hoặc đã hết lượt dùng'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: const Text('ÁP DỤNG'),
                      ),
                    ],
                  ),
                  if (appliedCouponCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Đã giảm $discountPercent% cho đơn hàng', style: const TextStyle(color: Colors.green)),
                    ),
                  
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(finalPrice),
                            style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                          ),
                          if (discountPercent > 0)
                            Text(
                              currencyFormat.format(currentPrice),
                              style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough),
                            ),
                        ],
                      ),
                    ],
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
                          // Tạo bản sao sản phẩm với giá đã giảm để lưu vào đơn hàng
                          final discountedProduct = ProductModel(
                            idString: widget.product.idString,
                            name: widget.product.name,
                            price: widget.product.price * (100 - discountPercent) / 100,
                            description: widget.product.description,
                            imageUrl: widget.product.imageUrl,
                            stock: widget.product.stock,
                          );

                          // Gọi FirebaseService để tạo bản ghi đơn hàng
                          await _firebaseService.placeOrder(
                            discountedProduct,
                            _quantity,
                            _selectedSize,
                            customerName: nameController.text.trim(),
                            customerPhone: phoneController.text.trim(),
                            customerAddress: addressController.text.trim(),
                          );

                          // Cập nhật số lần dùng mã
                          if (appliedCouponId != null) {
                            await _firebaseService.incrementCouponUsage(appliedCouponId!);
                          }

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
                        currencyFormat.format(widget.product.price * _quantity), // Hiển thị tổng giá dựa trên số lượng
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
                  
                  // --- PHẦN ĐÁNH GIÁ SẢN PHẨM ---
                  const Divider(),
                  const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // StreamBuilder để hiển thị danh sách các đánh giá ĐÃ DUYỆT
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firebaseService.getApprovedReviews(widget.product.idString!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final reviews = snapshot.data!;
                      if (reviews.isEmpty) return const Text('Chưa có đánh giá nào cho sản phẩm này.', style: TextStyle(color: Colors.grey));
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final r = reviews[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: (r['userImage'] != null && r['userImage'].toString().isNotEmpty) 
                                ? NetworkImage(r['userImage']) : null,
                              child: (r['userImage'] == null || r['userImage'].toString().isEmpty) 
                                ? const Icon(Icons.person) : null,
                            ),
                            title: Text(r['userName'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingBarIndicator(
                                  rating: (r['rating'] ?? 0).toDouble(),
                                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 15.0,
                                ),
                                Text(r['comment'] ?? ''),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  // Nút để mở Form đánh giá
                  OutlinedButton.icon(
                    onPressed: _showReviewForm, 
                    icon: const Icon(Icons.rate_review_outlined), 
                    label: const Text('VIẾT ĐÁNH GIÁ'),
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
