import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../models/order_model.dart';
import 'map_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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

  void _saveProfile() async {
    setState(() => _isUpdating = true);
    try {
      await _firebaseService.updateProfile(
          user!.uid, _nameController.text, _imageUrlController.text);

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
            // Header Profile
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
            
            // Edit Profile Section
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
            
            // Actions
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
                // Show a simple bottom sheet or navigate to an orders screen
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
                                      subtitle: Text('SL: ${order.quantity} - Trạng thái: ${order.status}'),
                                      trailing: Text('${order.price * order.quantity}đ', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
