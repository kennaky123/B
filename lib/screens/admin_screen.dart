import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

  void _showProductForm(ProductModel? product) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final imgController = TextEditingController();
    final multiImgController = TextEditingController();
    final sizeController = TextEditingController();
    final stockController = TextEditingController();

    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      descController.text = product.description;
      imgController.text = product.imageUrl;
      multiImgController.text = product.imageUrls.join(', ');
      sizeController.text = product.sizes.join(', ');
      stockController.text = product.stock.toString();
    } else {
      stockController.text = "100";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Thông tin sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
              TextField(controller: imgController, decoration: const InputDecoration(labelText: 'Link ảnh chính')),
              TextField(controller: multiImgController, decoration: const InputDecoration(labelText: 'Link các ảnh khác (phân cách bằng dấu phẩy)')),
              TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'Các size (S, M, L...)')),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Số lượng tồn kho'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final p = ProductModel(
                    idString: product?.idString,
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    description: descController.text,
                    imageUrl: imgController.text,
                    imageUrls: multiImgController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    sizes: sizeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                    stock: int.tryParse(stockController.text) ?? 100,
                  );
                  if (product == null) {
                    await _firebaseService.addProduct(p);
                  } else {
                    await _firebaseService.updateProduct(p);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(product == null ? 'Thêm mới' : 'Cập nhật'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(OrderModel order) {
    String selectedStatus = order.status;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật trạng thái đơn hàng'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          items: ['Processing', 'Shipping', 'Delivered']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => selectedStatus = val!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await _firebaseService.updateOrderStatus(
                order.id!, 
                selectedStatus,
                order.userId,
                order.productName,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Sản phẩm'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Đơn hàng'),
              Tab(icon: Icon(Icons.chat), text: 'Tin nhắn'),
            ],
            indicatorColor: Colors.white,
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/')),
          ],
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: QUẢN LÝ SẢN PHẨM ---
            StreamBuilder<List<ProductModel>>(
              stream: _firebaseService.getProductsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final products = snapshot.data!;
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return ListTile(
                      leading: Image.network(p.imageUrl, width: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                      title: Text(p.name),
                      subtitle: Text('Kho: ${p.stock} - Giá: ${currencyFormat.format(p.price)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(p)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _firebaseService.deleteProduct(p.idString!)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 2: XỬ LÝ ĐƠN HÀNG ---
            StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.getAllOrdersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!;
                if (orders.isEmpty) return const Center(child: Text('Chưa có đơn hàng nào.'));
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(o.productName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khách: ${o.customerName ?? "Chưa nhập"} - SDT: ${o.customerPhone ?? "Chưa nhập"}'),
                            Text('Địa chỉ: ${o.customerAddress ?? "Chưa nhập"}'),
                            Text('SL: ${o.quantity} - Size: ${o.size ?? "N/A"}'),
                            Text('Tổng: ${currencyFormat.format(o.price * o.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text('Trạng thái: ${o.status}', style: const TextStyle(color: Colors.orange)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showStatusDialog(o),
                          child: const Text('Xử lý'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 3: QUẢN LÝ TIN NHẮN (Messenger Style) ---
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firebaseService.getChatUsersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final chatUsers = snapshot.data!;
              if (chatUsers.isEmpty) return const Center(child: Text('Chưa có khách hàng nào nhắn tin.'));

              return ListView.builder(
                itemCount: chatUsers.length,
                itemBuilder: (context, index) {
                  final chatData = chatUsers[index];
                  final userId = chatData['userId'];

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                    builder: (context, userSnapshot) {
                      String displayName = 'Khách hàng';
                      String? userImage;
                      
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        displayName = userData['name'] ?? 'Khách hàng';
                        userImage = userData['imageUrl'];
                      }

                      final String lastMsg = chatData['lastMessage'] ?? 'Nhấn để trả lời tin nhắn';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (userImage != null && userImage.isNotEmpty)
                              ? NetworkImage(userImage)
                              : null,
                          child: (userImage == null || userImage.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(displayName),
                        subtitle: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                userId: userId,
                                userName: displayName,
                                isAdmin: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () => _showProductForm(null),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.add),
            );
          }
        ),
      ),
    );
  }
}
