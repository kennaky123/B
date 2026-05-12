import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';

/// Màn hình Chat chi tiết (ChatDetailScreen)
/// Chức năng:
/// - Hiển thị nội dung tin nhắn giữa một User cụ thể và Admin theo thời gian thực.
/// - Cho phép cả Admin và User gửi tin nhắn mới.
/// - Tự động cập nhật thông tin 'metadata' (tin nhắn cuối cùng, tên người dùng) để hiển thị ở danh sách Chat của Admin.
class ChatDetailScreen extends StatefulWidget {
  final String userId;      // ID của khách hàng
  final String userName;    // Tên hiển thị của đối phương
  final bool isAdmin;       // Cờ xác định người đang sử dụng màn hình này là Admin hay User

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdmin = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  /// Logic: Gửi tin nhắn
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();

    if (widget.isAdmin) {
      // Nếu là Admin gửi -> Gọi service của admin
      await _firebaseService.sendAdminMessage(widget.userId, text);
    } else {
      // Nếu là Khách hàng gửi:
      
      // 1. Lấy thông tin cá nhân hiện tại (Tên, Ảnh) để đồng bộ vào cuộc hội thoại
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final userName = userDoc.exists ? (userDoc.get('name') ?? 'Khách hàng') : 'Khách hàng';
      final userImage = userDoc.exists ? (userDoc.get('imageUrl') ?? '') : '';

      // 2. Cập nhật bản ghi cha trong collection 'chats' (để Admin thấy tin nhắn mới nhất ở ngoài danh sách)
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.userId)
          .set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'userName': userName,
        'userImage': userImage,
      }, SetOptions(merge: true));

      // 3. Thêm tin nhắn vào sub-collection 'messages' (đây là nơi chứa lịch sử chat thực sự)
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.userId)
          .collection('messages')
          .add({
        'senderId': widget.userId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Column(
        children: [
          // Phần 1: Danh sách tin nhắn (Thời gian thực)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Tin nhắn mới nhất hiển thị ở dưới cùng
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final senderId = msgData['senderId'];
                    
                    // Kiểm tra xem tin nhắn này là do mình gửi hay đối phương gửi
                    final bool isMe = widget.isAdmin 
                        ? (senderId == 'admin') 
                        : (senderId == widget.userId);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msgData['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Phần 2: Ô nhập liệu và nút Gửi
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
