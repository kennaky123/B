import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Màn hình Quản trị (AdminScreen)
/// Chức năng dành cho người quản lý:
/// - Quản lý Sản phẩm (Thêm, Sửa, Xóa).
/// - Quản lý Đơn hàng (Xem danh sách, Cập nhật trạng thái giao hàng).
/// - Quản lý Tin nhắn (Chat với khách hàng).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

  /// Hiển thị Form để Thêm mới hoặc Cập nhật sản phẩm
  void _showProductForm(ProductModel? product) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final imgController = TextEditingController();
    final multiImgController = TextEditingController();
    final sizeController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'Áo';

    final categories = ['Áo', 'Quần', 'Phụ kiện', 'Giày'];

    // Nếu là cập nhật, điền sẵn thông tin cũ vào các ô nhập
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      descController.text = product.description;
      imgController.text = product.imageUrl;
      multiImgController.text = product.imageUrls.join(', ');
      sizeController.text = product.sizes.join(', ');
      stockController.text = product.stock.toString();
      selectedCategory = categories.contains(product.category) ? product.category : 'Áo';
    } else {
      stockController.text = "100"; // Mặc định kho có 100 sản phẩm khi thêm mới
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(product == null ? 'Thêm sản phẩm mới' : 'Cập nhật sản phẩm', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Danh mục (Tag)', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedCategory = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()), maxLines: 2),
                    const SizedBox(height: 12),
                    TextField(controller: imgController, decoration: const InputDecoration(labelText: 'Link ảnh chính', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: multiImgController, decoration: const InputDecoration(labelText: 'Link các ảnh khác (phân cách bằng dấu phẩy)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'Các size (S, M, L...)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Số lượng tồn kho', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Tạo đối tượng model từ dữ liệu nhập vào
                          final p = ProductModel(
                            idString: product?.idString,
                            name: nameController.text,
                            price: double.tryParse(priceController.text) ?? 0,
                            description: descController.text,
                            imageUrl: imgController.text,
                            imageUrls: multiImgController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            sizes: sizeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            stock: int.tryParse(stockController.text) ?? 100,
                            category: selectedCategory,
                          );
                          // Gọi Firebase để lưu dữ liệu
                          if (product == null) {
                            await _firebaseService.addProduct(p);
                          } else {
                            await _firebaseService.updateProduct(p);
                          }
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: Text(product == null ? 'THÊM MỚI' : 'CẬP NHẬT'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  /// Hiển thị hộp thoại để Admin đổi trạng thái đơn hàng (Đang xử lý -> Đang giao -> Đã giao)
  void _showStatusDialog(OrderModel order) {
    String selectedStatus = order.status;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trạng thái đơn hàng'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: ['Processing', 'Shipping', 'Delivered']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => selectedStatus = val!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              // Cập nhật trạng thái và gửi thông báo cho User
              await _firebaseService.updateOrderStatus(
                order.id!, 
                selectedStatus,
                order.userId,
                order.productName,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị Form tạo mã giảm giá mới
  void _showCouponForm() {
    final codeController = TextEditingController();
    final percentController = TextEditingController();
    final usageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo mã giảm giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Mã (VD: GIAM20)', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentController,
              decoration: const InputDecoration(labelText: 'Phần trăm giảm (%)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usageController,
              decoration: const InputDecoration(labelText: 'Số lần sử dụng tối đa', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty || percentController.text.isEmpty || usageController.text.isEmpty) return;
              await _firebaseService.addCoupon(
                codeController.text.trim(),
                double.tryParse(percentController.text) ?? 0,
                int.tryParse(usageController.text) ?? 10,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('TẠO MÃ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị cửa hàng'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Sản phẩm'),
              Tab(text: 'Đơn hàng'),
              Tab(text: 'Chat'),
              Tab(text: 'Đánh giá'),
              Tab(text: 'Coupon'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          actions: [
            // Đăng xuất Admin
            IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/')),
          ],
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: QUẢN LÝ SẢN PHẨM ---
            StreamBuilder<List<ProductModel>>(
              stream: _firebaseService.getProductsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final products = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(p.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Giá: ${currencyFormat.format(p.price)}\nKho: ${p.stock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(p)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _firebaseService.deleteProduct(p.idString!)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 2: QUẢN LÝ ĐƠN HÀNG ---
            StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.getAllOrdersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!;
                if (orders.isEmpty) return const Center(child: Text('Chưa có đơn hàng nào.'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Sử dụng Expanded để tên sản phẩm tự xuống dòng nếu quá dài, tránh lỗi tràn màn hình (Overflow)
                                Expanded(
                                  child: Text(
                                    o.productName, 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: o.status == 'Delivered' ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(o.status, style: TextStyle(color: o.status == 'Delivered' ? Colors.green : Colors.orange, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                // Thêm nút xóa đơn hàng dành cho Admin
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xóa đơn hàng?'),
                                        content: const Text('Bạn có chắc chắn muốn xóa đơn hàng này khỏi hệ thống?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
                                          TextButton(
                                            onPressed: () async {
                                              await _firebaseService.deleteOrder(o.id!, o.userId, o.productName);
                                              if (!mounted) return;
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Khách: ${o.customerName ?? "Chưa nhập"}'),
                            Text('SĐT: ${o.customerPhone ?? "Chưa nhập"}'),
                            Text('Địa chỉ: ${o.customerAddress ?? "Chưa nhập"}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('SL: ${o.quantity} - Size: ${o.size ?? "N/A"}'),
                                ),
                                Text(
                                  currencyFormat.format(o.price * o.quantity), 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _showStatusDialog(o),
                                child: const Text('CẬP NHẬT TRẠNG THÁI'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 3: QUẢN LÝ TIN NHẮN (LIST CHAT) ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getChatUsersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final chatUsers = snapshot.data!;
                if (chatUsers.isEmpty) return const Center(child: Text('Chưa có tin nhắn nào.'));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final chatData = chatUsers[index];
                    final userId = chatData['userId'];

                    // Lấy tên/ảnh User từ Firestore
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                      builder: (context, userSnapshot) {
                        String displayName = 'Khách hàng';
                        String? userImage;
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          displayName = userData['name'] ?? 'Khách hàng';
                          userImage = userData['imageUrl'];
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (userImage != null && userImage.isNotEmpty) ? NetworkImage(userImage) : null,
                            child: (userImage == null || userImage.isEmpty) ? const Icon(Icons.person) : null,
                          ),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(chatData['lastMessage'] ?? 'Nhấn để xem tin nhắn', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Mở màn hình chat chi tiết với User này
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  userId: userId,
                                  userName: displayName,
                                  isAdmin: true,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            // --- TAB 4: QUẢN LÝ ĐÁNH GIÁ (REVIEWS) ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.getAllReviewsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final reviews = snapshot.data!;
                if (reviews.isEmpty) return const Center(child: Text('Chưa có đánh giá nào.'));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = reviews[index];
                    final bool isApproved = r['isApproved'] ?? false;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isApproved ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: (r['userImage'] != null && r['userImage'].toString().isNotEmpty) 
                                ? NetworkImage(r['userImage']) : null,
                              child: (r['userImage'] == null || r['userImage'].toString().isEmpty) 
                                ? const Icon(Icons.person) : null,
                            ),
                            title: Text(r['userName'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.bold)),
                            // Wrap subtitle in Expanded if needed, but ListTile handles this usually. 
                            // Thêm subtitle để hiển thị tên sản phẩm thay vì chỉ ID
                            subtitle: Text('SP: ${r['productId']}', overflow: TextOverflow.ellipsis),
                            trailing: Container(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                isApproved ? 'ĐÃ DUYỆT' : 'CHỜ DUYỆT',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: (r['rating'] ?? 0).toDouble(),
                                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                itemCount: 5,
                                itemSize: 20.0,
                              ),
                              const Spacer(),
                              Text(
                                (r['timestamp'] != null) 
                                  ? (r['timestamp'] as Timestamp).toDate().toString().substring(0, 16)
                                  : '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r['comment'] ?? '', style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Nút Duyệt / Hủy duyệt
                              ElevatedButton(
                                onPressed: () => _firebaseService.updateReviewApproval(r['id'], !isApproved),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isApproved ? Colors.orange : Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(isApproved ? 'GỠ BỎ (HỦY DUYỆT)' : 'PHÊ DUYỆT'),
                              ),
                              const SizedBox(width: 8),
                              // Nút Xóa vĩnh viễn
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xác nhận xóa'),
                                      content: const Text('Bạn có chắc chắn muốn xóa đánh giá này không?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                                        TextButton(
                                          onPressed: () {
                                            _firebaseService.deleteReview(r['id']);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('XÓA', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 5: QUẢN LÝ MÃ GIẢM GIÁ (COUPONS) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCouponForm,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('TẠO MÃ GIẢM GIÁ MỚI'),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firebaseService.getCouponsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final coupons = snapshot.data!;
                        if (coupons.isEmpty) return const Center(child: Text('Chưa có mã giảm giá nào.'));

                        return ListView.builder(
                          itemCount: coupons.length,
                          itemBuilder: (context, index) {
                            final c = coupons[index];
                            final bool isActive = c['isActive'] ?? true;

                            return Card(
                              child: ListTile(
                                title: Text(c['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Text('Giảm: ${c['discountPercent']}% - Dùng: ${c['usedCount']}/${c['maxUsage']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _firebaseService.deleteCoupon(c['id']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Nút tròn để thêm sản phẩm mới nhanh
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showProductForm(null),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
