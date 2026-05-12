import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

/// FirebaseService: Lớp tập trung tất cả các truy vấn gửi tới Firebase
/// Giúp quản lý code sạch sẽ, dễ bảo trì và tái sử dụng.
class FirebaseService {
  // Tham chiếu (Reference) tới các bộ sưu tập (Collection) trên Firestore
  final CollectionReference productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference ordersRef =
  FirebaseFirestore.instance.collection('orders');
  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('users');

  // ===================== SẢN PHẨM (PRODUCTS) =====================

  /// Lấy danh sách sản phẩm theo thời gian thực (Stream)
  /// Dữ liệu sẽ tự động cập nhật khi Firestore có thay đổi.
  Stream<List<ProductModel>> getProductsStream() {
    return productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(
            doc.data() as Map<String, dynamic>, id: doc.id);
      }).toList();
    });
  }

  /// Thêm sản phẩm mới (Thường dùng cho Admin)
  Future<void> addProduct(ProductModel product) =>
      productsRef.add(product.toMap());

  /// Cập nhật thông tin sản phẩm
  Future<void> updateProduct(ProductModel product) {
    if (product.idString == null) return Future.error("ID không hợp lệ");
    return productsRef.doc(product.idString).update(product.toMap());
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String id) => productsRef.doc(id).delete();

  // ===================== ĐƠN HÀNG (ORDERS) =====================

  /// Cập nhật trạng thái đơn hàng và gửi thông báo cho người dùng
  Future<void> updateOrderStatus(String orderId, String newStatus, String userId, String productName) async {
    // 1. Cập nhật trạng thái trong collection 'orders'
    await ordersRef.doc(orderId).update({'status': newStatus});

    // 2. Tự động tạo một thông báo mới trong collection 'notifications'
    // Màn hình Notifications sẽ lắng nghe dữ liệu từ đây.
    String title = "Cập nhật đơn hàng";
    String body = "Đơn hàng '$productName' của bạn đã chuyển sang trạng thái: $newStatus";

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy tất cả đơn hàng (Dành cho Admin)
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

  /// Đặt hàng mới
  /// - Tạo bản ghi đơn hàng
  /// - Trừ số lượng tồn kho của sản phẩm
  Future<void> placeOrder(ProductModel product, int quantity, String? size, {String? customerName, String? customerPhone, String? customerAddress}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.error("Chưa đăng nhập");
    
    // Kiểm tra hàng tồn kho trước khi đặt
    if (product.stock < quantity) {
      return Future.error("Không đủ hàng trong kho");
    }

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

    // 1. Lưu thông tin đơn hàng
    await ordersRef.add(order.toMap());

    // 2. Cập nhật lại số lượng hàng còn lại (Stock) của sản phẩm đó
    await productsRef.doc(product.idString).update({
      'stock': product.stock - quantity,
    });
  }

  /// Lấy danh sách đơn hàng của một người dùng cụ thể
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

  // ===================== NGƯỜI DÙNG (USER PROFILE) =====================

  /// Lấy thông tin cá nhân từ Firestore
  Future<DocumentSnapshot> getUserProfile(String userId) {
    return usersRef.doc(userId).get();
  }

  /// Cập nhật thông tin cá nhân (Tên, Ảnh đại diện)
  Future<void> updateProfile(String userId, String name, String? imageUrl) {
    Map<String, dynamic> data = {'name': name};
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    return usersRef.doc(userId).update(data);
  }

  // ===================== CHAT (HỖ TRỢ KHÁCH HÀNG) =====================

  /// Lấy danh sách các cuộc hội thoại (Dành cho Admin)
  Stream<List<Map<String, dynamic>>> getChatUsersStream() {
    return FirebaseFirestore.instance.collection('chats').snapshots().map((
        snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'userName': data['userName'] ?? 'Khách hàng',
          'userImage': data['userImage'],
          'lastMessage': data['lastMessage'],
        };
      }).toList();
    });
  }

  /// Gửi tin nhắn từ Admin tới người dùng
  Future<void> sendAdminMessage(String userId, String text) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      'senderId': 'admin', // Đánh dấu là tin nhắn của Admin
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
