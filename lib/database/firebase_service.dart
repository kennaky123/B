import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final CollectionReference productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference ordersRef =
  FirebaseFirestore.instance.collection('orders');
  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('users');

  // --- Products ---
  Stream<List<ProductModel>> getProductsStream() {
    return productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(
            doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();
    });
  }

  Future<void> addProduct(ProductModel product) =>
      productsRef.add(product.toMap());

  Future<void> updateProduct(ProductModel product) {
    if (product.idString == null) return Future.error("ID không hợp lệ");
    return productsRef.doc(product.idString).update(product.toMap());
  }

  Future<void> deleteProduct(String id) => productsRef.doc(id).delete();

  // --- Orders ---
  Future<void> updateOrderStatus(String orderId, String newStatus, String userId, String productName) async {
    // 1. Cập nhật trạng thái đơn hàng
    await ordersRef.doc(orderId).update({'status': newStatus});

    // 2. Tự động tạo thông báo cho User
    String title = "Cập nhật đơn hàng";
    String body = "Đơn hàng '$productName' của bạn đã chuyển sang trạng thái: $newStatus";

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<OrderModel>> getAllOrdersStream() {
    return ordersRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- Orders ---
  Future<void> placeOrder(ProductModel product, int quantity, String? size, {String? customerName, String? customerPhone, String? customerAddress}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.error("Chưa đăng nhập");
    if (product.stock < quantity)
      return Future.error("Không đủ hàng trong kho");

    final order = OrderModel(
      userId: user.uid,
      productId: product.idString!,
      productName: product.name,
      size: size,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      price: product.price,
      quantity: quantity,
      status: 'Processing',
      timestamp: DateTime.now(),
    );

    // 1. Tạo đơn hàng
    await ordersRef.add(order.toMap());

    // 2. Trừ số lượng trong kho
    await productsRef.doc(product.idString).update({
      'stock': product.stock - quantity,
    });
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- User Profile ---
  Future<DocumentSnapshot> getUserProfile(String userId) {
    return usersRef.doc(userId).get();
  }

  Future<void> updateProfile(String userId, String name, String? imageUrl) {
    Map<String, dynamic> data = {'name': name};
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    return usersRef.doc(userId).update(data);
  }

  // --- Chat ---
  Stream<List<Map<String, dynamic>>> getChatUsersStream() {
    return FirebaseFirestore.instance.collection('chats').snapshots().map((
        snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userId': doc.id,
          'userName': data['userName'] ?? 'Khách hàng',
          'userImage': data['userImage'],
          'lastMessage': data['lastMessage'],
        };
      }).toList();
    });
  }

  Future<void> sendAdminMessage(String userId, String text) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      'senderId': 'admin', // Định danh admin
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
