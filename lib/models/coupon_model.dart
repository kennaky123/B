import 'package:cloud_firestore/cloud_firestore.dart';

/// CouponModel: Đại diện cho mã giảm giá trong hệ thống
class CouponModel {
  final String? id;             // ID mã trên Firestore
  final String code;           // Mã giảm giá (ví dụ: GIAM20)
  final double discountPercent; // Phần trăm giảm (ví dụ: 20.0 cho 20%)
  final int maxUsage;          // Số lần sử dụng tối đa (VD: 100 lần)
  final int usedCount;         // Số lần đã sử dụng thực tế
  final DateTime? expiryDate;   // Ngày hết hạn (tùy chọn)

  CouponModel({
    this.id,
    required this.code,
    required this.discountPercent,
    this.maxUsage = 0,         // 0 có thể coi là không giới hạn hoặc cần nhập số cụ thể
    this.usedCount = 0,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'discountPercent': discountPercent,
      'maxUsage': maxUsage,
      'usedCount': usedCount,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      id: id,
      code: map['code'] ?? '',
      discountPercent: (map['discountPercent'] ?? 0).toDouble(),
      maxUsage: map['maxUsage'] ?? 0,
      usedCount: map['usedCount'] ?? 0,
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
    );
  }
}
