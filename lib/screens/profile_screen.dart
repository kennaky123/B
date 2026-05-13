import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../models/order_model.dart';
import 'map_screen.dart';
import 'package:intl/intl.dart';

/// Màn hình Tài khoản (ProfileScreen)
/// Chức năng:
/// - Hiển thị thông tin cá nhân (Ảnh đại diện, Tên, Email).
/// - Chỉnh sửa thông tin cá nhân.
/// - Xem lịch sử đơn hàng của bản thân.
/// - Xem vị trí cửa hàng trên bản đồ.
/// - Đăng xuất khỏi ứng dụng.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final user = FirebaseAuth.instance.currentUser;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
  
  // Các bộ điều khiển để sửa thông tin
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Tải dữ liệu người dùng hiện tại từ Firestore
  void _loadUserData() async {
    if (user != null) {
      final doc = await _firebaseService.getUserProfile(user!.uid);
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.get('name') ?? '';
          _imageUrlController.text = doc.get('imageUrl') ?? '';
        });
      }
    }
  }

  /// Lưu thông tin cá nhân sau khi chỉnh sửa
  void _saveProfile() async {
    setState(() => _isUpdating = true);
    try {
      // 1. Cập nhật trong collection 'users'
      await _firebaseService.updateProfile(
          user!.uid, _nameController.text, _imageUrlController.text);

      // 2. Cập nhật đồng bộ sang collection 'chats' để Admin thấy tên mới
      await FirebaseFirestore.instance.collection('chats').doc(user!.uid).set({
        'userName': _nameController.text,
        'userImage': _imageUrlController.text,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin cá nhân!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Xác nhận hủy đơn hàng
  void _confirmCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không? Số lượng sản phẩm sẽ được hoàn lại vào kho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KHÔNG')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firebaseService.cancelOrder(order);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã hủy đơn hàng thành công'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('HỦY NGAY', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Xác nhận xóa đơn hàng khỏi lịch sử
  void _confirmDeleteOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử đơn hàng?'),
        content: const Text('Hành động này sẽ xóa đơn hàng khỏi danh sách của bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firebaseService.deleteOrder(order.id!, user!.uid, order.productName);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa đơn hàng khỏi lịch sử')),
              );
            },
            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Phần hiển thị Profile (Lắng nghe Stream để cập nhật ảnh/tên tức thì)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                String? imageUrl = snapshot.data?.get('imageUrl');
                String? name = snapshot.data?.get('name');
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                      child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(name ?? 'Người dùng', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(user!.email ?? '', style: TextStyle(color: Colors.grey[600])),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            
            // Phần chỉnh sửa thông tin (ExpansionTile giúp thu gọn/mở rộng)
            ExpansionTile(
              title: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.edit_outlined),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên hiển thị', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(labelText: 'Link ảnh đại diện', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _saveProfile,
                          child: _isUpdating ? const CircularProgressIndicator() : const Text('LƯU THAY ĐỔI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Các nút chức năng khác
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Địa chỉ cửa hàng (Map)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử đơn hàng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Hiển thị danh sách đơn hàng của người dùng trong một Bottom Sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Đơn hàng của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Expanded(
                          child: StreamBuilder<List<OrderModel>>(
                            stream: _firebaseService.getUserOrders(user!.uid),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              final orders = snapshot.data!;
                              if (orders.isEmpty) return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
                              return ListView.builder(
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  final order = orders[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('SL: ${order.quantity} - Trạng thái: ${order.status}'),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              // Nút Hủy đơn: Chỉ hiện khi đang xử lý (Processing)
                                              if (order.status == 'Processing')
                                                TextButton.icon(
                                                  onPressed: () => _confirmCancelOrder(order),
                                                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                                  label: const Text('HỦY ĐƠN', style: TextStyle(color: Colors.red, fontSize: 12)),
                                                ),
                                              // Nút Xóa: Chỉ hiện khi đã giao hoặc đã hủy
                                              if (order.status == 'Cancelled' || order.status == 'Delivered')
                                                TextButton.icon(
                                                  onPressed: () => _confirmDeleteOrder(order),
                                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                                  label: const Text('XÓA', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        currencyFormat.format(order.price * order.quantity), // Tính tổng tiền: đơn giá * số lượng
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
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
                );
              },
            ),
            const Divider(),
            // Nút Đăng xuất
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                FirebaseAuth.instance.signOut();
                // Quay về màn hình Login (initialRoute '/')
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
