import 'package:cloud_firestore/cloud_firestore.dart';

/// ReviewModel: Đại diện cho một đánh giá sản phẩm từ người dùng
class ReviewModel {
  final String? id;           // ID của bản ghi đánh giá trên Firestore
  final String productId;    // ID của sản phẩm được đánh giá
  final String userId;       // ID người đánh giá
  final String userName;     // Tên người đánh giá (lấy từ Profile)
  final String? userImage;   // Ảnh đại diện người đánh giá
  final String comment;      // Nội dung bình luận
  final double rating;       // Số sao (ví dụ: 4.5 sao)
  final bool isApproved;     // Trạng thái duyệt: true (hiển thị), false (đang chờ duyệt)
  final DateTime timestamp;  // Thời gian gửi đánh giá

  ReviewModel({
    this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.comment,
    required this.rating,
    this.isApproved = false,
    required this.timestamp,
  });

  /// Chuyển đổi sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'comment': comment,
      'rating': rating,
      'isApproved': isApproved,
      'timestamp': timestamp,
    };
  }

  /// Khởi tạo đối tượng từ dữ liệu Map của Firestore
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Khách hàng',
      userImage: map['userImage'],
      comment: map['comment'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      isApproved: map['isApproved'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
