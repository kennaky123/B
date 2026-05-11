import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    // Với User, nhấn vào icon Chat sẽ mở thẳng hội thoại với Admin
    return ChatDetailScreen(
      userId: user.uid,
      userName: 'Hỗ trợ Admin',
      isAdmin: false,
    );
  }
}
