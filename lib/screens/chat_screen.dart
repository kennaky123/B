import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

/// Màn hình Tin nhắn (ChatScreen) - Dành cho khách hàng
/// Chức năng:
/// - Đối với khách hàng, màn hình này đóng vai trò là "lối vào" nhanh.
/// - Khi khách hàng mở tab Chat, ứng dụng sẽ mở thẳng màn hình ChatDetailScreen 
///   để kết nối trực tiếp với tài khoản hỗ trợ của Admin.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra trạng thái đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    // Với User, nhấn vào tab Chat sẽ mở thẳng hội thoại với Admin.
    // Dữ liệu chat sẽ được lưu trong Firestore dưới ID của chính User này.
    return ChatDetailScreen(
      userId: user.uid,
      userName: 'Hỗ trợ Admin',
      isAdmin: false, // Đánh dấu đây là vai trò khách hàng đang chat
    );
  }
}
