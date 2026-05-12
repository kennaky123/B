import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Màn hình Thông báo (NotificationsScreen)
/// Chức năng:
/// - Lắng nghe danh sách thông báo từ Firestore (collection 'notifications') dành riêng cho User hiện tại.
/// - Hiển thị các cập nhật như: "Đơn hàng đã được duyệt", "Đang giao hàng", v.v.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy ID người dùng hiện tại
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem thông báo'))
          : StreamBuilder<QuerySnapshot>(
              // Lấy các thông báo có userId khớp với người dùng đang đăng nhập
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bạn chưa có thông báo nào.'));
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final data = notifications[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.notifications),
                        ),
                        title: Text(data['title'] ?? 'Thông báo'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['body'] ?? ''),
                            const SizedBox(height: 4),
                            // Hiển thị thời gian nhận thông báo
                            Text(
                              (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
