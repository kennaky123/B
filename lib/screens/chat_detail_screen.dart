import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isAdmin;

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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();

    if (widget.isAdmin) {
      await _firebaseService.sendAdminMessage(widget.userId, text);
    } else {
      // 1. Lấy thông tin user hiện tại để lưu vào metadata chat
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final userName = userDoc.exists ? (userDoc.get('name') ?? 'Khách hàng') : 'Khách hàng';
      final userImage = userDoc.exists ? (userDoc.get('imageUrl') ?? '') : '';

      // 2. Tạo/Cập nhật document cha với đầy đủ thông tin hiển thị
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.userId)
          .set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'userName': userName,
        'userImage': userImage,
      }, SetOptions(merge: true));

      // 3. Thêm tin nhắn vào sub-collection
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
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final senderId = msgData['senderId'];
                    final bool isMe = widget.isAdmin ? (senderId == 'admin') : (senderId == widget.userId);

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
