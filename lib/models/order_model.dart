import 'package:cloud_firestore/cloud_firestore.dart';

/// OrderModel: Đại diện cho cấu trúc dữ liệu của một Đơn hàng
class OrderModel {
  final String? id;               // ID đơn hàng trên Firestore
  final String userId;            // ID của người mua
  final String productId;         // ID của sản phẩm được mua
  final String productName;       // Tên sản phẩm tại thời điểm mua
  final String? size;             // Kích cỡ người dùng đã chọn
  final String? customerName;     // Tên người nhận (nhập khi thanh toán)
  final String? customerPhone;    // Số điện thoại nhận hàng
  final String? customerAddress;  // Địa chỉ giao hàng
  final double price;             // Giá sản phẩm tại thời điểm mua
  final int quantity;             // Số lượng mua
  final String status;            // Trạng thái: 'Processing' (Đang xử lý), 'Shipping' (Đang giao), 'Delivered' (Đã giao)
  final DateTime timestamp;       // Thời gian đặt hàng

  OrderModel({
    this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    this.size,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.price,
    required this.quantity,
    required this.status,
    required this.timestamp,
  });

  /// Chuyển đổi sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'size': size,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'price': price,
      'quantity': quantity,
      'status': status,
      'timestamp': timestamp, // Firestore sẽ tự động chuyển DateTime thành Timestamp
    };
  }

  /// Khởi tạo từ dữ liệu Firestore (Map)
  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      size: map['size'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      customerAddress: map['customerAddress'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      status: map['status'] ?? 'Processing',
      // Khi lấy từ Firestore, timestamp trả về kiểu 'Timestamp', cần chuyển sang 'DateTime' của Dart
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
