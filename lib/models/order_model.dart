import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String userId;
  final String productId;
  final String productName;
  final String? size; // Thêm size đã chọn
  final String? customerName; // Tên khách hàng nhập lúc checkout
  final String? customerPhone; // Số điện thoại
  final String? customerAddress; // Địa chỉ
  final double price;
  final int quantity;
  final String status; // 'Processing', 'Shipping', 'Delivered'
  final DateTime timestamp;

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
      'timestamp': timestamp,
    };
  }

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
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
