import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../database/firebase_service.dart';
import '../models/order_model.dart';

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
      // 1. Cập nhật bảng users (cho Profile của user)
      await _firebaseService.updateProfile(
          user!.uid, _nameController.text, _imageUrlController.text);

      // 2. Cập nhật bảng chats (để Admin thấy tên mới ngay lập tức)
      await FirebaseFirestore.instance.collection('chats').doc(user!.uid).set({
        'userName': _nameController.text,
        'userImage': _imageUrlController.text,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin cá nhân!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân & Đơn hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Profile Section ---
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String? imageUrl = snapshot.data?.get('imageUrl');
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên của bạn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Link ảnh đại diện (URL)',
                border: OutlineInputBorder(),
                hintText: 'Nhập link ảnh .jpg hoặc .png',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _saveProfile,
                child: _isUpdating
                    ? const CircularProgressIndicator()
                    : const Text('Lưu thông tin'),
              ),
            ),
            const Divider(height: 40),
            // --- Orders Section ---
            const Text('Đơn hàng của bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.getUserOrders(user!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final orders = snapshot.data!;
                if (orders.isEmpty) return const Text('Bạn chưa có đơn hàng nào.');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        title: Text(order.productName),
                        subtitle: Text('SL: ${order.quantity} - Tổng: ${order.price * order.quantity} VNĐ\nTrạng thái: ${order.status}'),
                        trailing: Text(order.timestamp.toString().substring(0, 10)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
