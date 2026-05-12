import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/firebase_service.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

/// Màn hình Trang chủ (HomeScreen)
/// Chức năng:
/// - Hiển thị Banner khuyến mãi.
/// - Hiển thị danh sách sản phẩm theo danh mục.
/// - Cho phép lọc sản phẩm theo category (Áo, Quần, v.v.).
/// - Nút đi tới giỏ hàng với biểu tượng thông báo số lượng sản phẩm.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Trạng thái lọc danh mục
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Áo', 'Quần', 'Phụ kiện', 'Giày'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar tùy chỉnh (SliverAppBar) có hiệu ứng cuộn
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 60,
            title: const Text(
              'Shop Quần Áo',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            actions: [
              // Nút Giỏ hàng kèm theo Badge số lượng
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                    onPressed: () {
                      // Chuyển sang màn hình Giỏ hàng
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Consumer<CartProvider>(
                      // Lắng nghe sự thay đổi của CartProvider để cập nhật số lượng
                      builder: (_, cart, ch) => cart.itemCount > 0 
                        ? Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${cart.itemCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        : const SizedBox.shrink(),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Banner quảng cáo / Khuyến mãi
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.deepOrange, Colors.orange[300]!],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.shopping_bag, size: 150, color: Colors.white.withOpacity(0.2)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BST Mùa Hè 2024',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Giảm giá đến 50%',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thanh chọn Danh mục (Category Filter)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.symmetric(vertical: 8)),

          // Lưới sản phẩm (Product Grid) - Lấy dữ liệu từ Firestore
          StreamBuilder<List<ProductModel>>(
            stream: _firebaseService.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              } else if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Lỗi: ${snapshot.error}')));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Không có sản phẩm nào')));
              } else {
                var products = snapshot.data!;
                
                // Logic lọc sản phẩm theo danh mục đã chọn
                if (_selectedCategory != 'Tất cả') {
                  products = products.where((p) => p.category == _selectedCategory).toList();
                }

                if (products.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('Không có sản phẩm nào thuộc danh mục này')));
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Trả về Widget Card cho từng sản phẩm
                        return ProductCard(product: products[index]);
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              }
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
