import 'package:cloud_firestore/cloud_firestore.dart';

/// ChatMessage: Đại diện cho một tin nhắn trong cuộc hội thoại
class ChatMessage {
  final String id;              // ID của tin nhắn trong Firestore
  final String senderId;        // ID người gửi (UID của User hoặc 'admin')
  final String text;            // Nội dung tin nhắn
  final DateTime timestamp;     // Thời điểm gửi tin nhắn

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  /// Chuyển sang Map để lưu vào sub-collection 'messages' trên Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }

  /// Khởi tạo từ Map (Dữ liệu từ Firestore)
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
