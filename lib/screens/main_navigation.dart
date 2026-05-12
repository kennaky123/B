import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// Màn hình Điều hướng chính (MainNavigation)
/// Chức năng: 
/// - Là "khung" chứa các màn hình chính của ứng dụng dành cho khách hàng.
/// - Sử dụng BottomNavigationBar để chuyển đổi giữa các tab.
/// - Dùng IndexedStack để giữ trạng thái của các màn hình khi chuyển tab (không bị load lại từ đầu).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Chỉ số tab đang được chọn (0: Trang chủ, 1: Thông báo, 2: Tin nhắn, 3: Cá nhân)
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với từng tab
  static const List<Widget> _screens = [
    HomeScreen(),
    NotificationsScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  /// Xử lý khi người dùng nhấn vào một icon dưới thanh điều hướng
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp hiển thị màn hình dựa theo index mà không làm mất trạng thái của màn hình đó
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // Thanh điều hướng phía dưới (Bottom Bar)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5), // Tạo bóng đổ nhẹ phía trên thanh bar
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Tin nhắn',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
