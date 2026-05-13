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

  /// Hủy đơn hàng (Dành cho User)
  /// - Cập nhật trạng thái thành 'Cancelled'
  /// - Cộng lại số lượng vào kho sản phẩm
  /// - Gửi thông báo xác nhận cho User
  Future<void> cancelOrder(OrderModel order) async {
    if (order.id == null) return;

    // 1. Cập nhật trạng thái đơn hàng
    await ordersRef.doc(order.id).update({'status': 'Cancelled'});

    // 2. Hoàn trả số lượng vào kho (Stock)
    DocumentSnapshot productDoc = await productsRef.doc(order.productId).get();
    if (productDoc.exists) {
      int currentStock = productDoc.get('stock') ?? 0;
      await productsRef.doc(order.productId).update({
        'stock': currentStock + order.quantity,
      });
    }

    // 3. Tạo thông báo cho người dùng
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': order.userId,
      'title': 'Đã hủy đơn hàng',
      'body': "Bạn đã hủy thành công đơn hàng '${order.productName}'.",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa đơn hàng (Dành cho User - Xóa khỏi lịch sử)
  Future<void> deleteOrder(String orderId, String userId, String productName) async {
    await ordersRef.doc(orderId).delete();

    // Thông báo xóa thành công
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': 'Đã xóa đơn hàng',
      'body': "Đơn hàng '$productName' đã được xóa khỏi lịch sử của bạn.",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa thông báo (Dành cho User)
  Future<void> deleteNotification(String notificationId) {
    return FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
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

  // ===================== ĐÁNH GIÁ (REVIEWS) =====================

  /// Gửi đánh giá mới (Mặc định isApproved = false)
  Future<void> addReview(String productId, String userId, String userName, String? userImage, String comment, double rating) {
    return FirebaseFirestore.instance.collection('reviews').add({
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'comment': comment,
      'rating': rating,
      'isApproved': false, // Cần admin duyệt mới hiển thị
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy danh sách đánh giá đã được duyệt của một sản phẩm
  Stream<List<Map<String, dynamic>>> getApprovedReviews(String productId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .where('isApproved', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Lấy tất cả đánh giá (Dành cho Admin quản lý)
  Stream<List<Map<String, dynamic>>> getAllReviewsStream() {
    return FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Cập nhật trạng thái duyệt của đánh giá
  Future<void> updateReviewApproval(String reviewId, bool isApproved) {
    return FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
      'isApproved': isApproved,
    });
  }

  /// Xóa đánh giá
  Future<void> deleteReview(String reviewId) {
    return FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
  }

  // ===================== MÃ GIẢM GIÁ (COUPONS) =====================

  /// Thêm mã giảm giá mới với số lần sử dụng tối đa
  Future<void> addCoupon(String code, double percent, int maxUsage) {
    return FirebaseFirestore.instance.collection('coupons').add({
      'code': code.toUpperCase(),
      'discountPercent': percent,
      'maxUsage': maxUsage,
      'usedCount': 0, // Mới tạo thì chưa ai dùng
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy danh sách mã giảm giá (Dành cho Admin)
  Stream<List<Map<String, dynamic>>> getCouponsStream() {
    return FirebaseFirestore.instance
        .collection('coupons')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Xóa mã giảm giá
  Future<void> deleteCoupon(String couponId) {
    return FirebaseFirestore.instance.collection('coupons').doc(couponId).delete();
  }

  /// Kiểm tra mã giảm giá (Dành cho User)
  /// Điều kiện: Mã tồn tại và UsedCount < MaxUsage
  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('coupons')
        .where('code', isEqualTo: code.toUpperCase())
        .get();

    if (snapshot.docs.isEmpty) return null;
    
    final data = snapshot.docs.first.data();
    int maxUsage = data['maxUsage'] ?? 0;
    int usedCount = data['usedCount'] ?? 0;

    // Nếu số lần dùng đã đạt tối đa thì mã không hợp lệ
    if (usedCount >= maxUsage) return null;

    return {...data, 'id': snapshot.docs.first.id};
  }

  /// Cập nhật số lần đã sử dụng của mã (+1 sau mỗi lần đặt hàng thành công)
  Future<void> incrementCouponUsage(String couponId) {
    return FirebaseFirestore.instance.collection('coupons').doc(couponId).update({
      'usedCount': FieldValue.increment(1),
    });
  }
}
