import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/cart_provider.dart';

/// Hàm main: Điểm khởi đầu của ứng dụng
void main() async {
  // Đảm bảo các dịch vụ của Flutter đã được khởi tạo trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase - Cần thiết để sử dụng Authentication, Firestore, v.v.
  await Firebase.initializeApp();
  
  // Chạy ứng dụng gốc
  runApp(const MyApp());
}

/// Class MyApp: Cấu hình chính của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng MultiProvider để quản lý trạng thái toàn cục (Global State)
    // Tại đây ta cung cấp CartProvider cho toàn bộ ứng dụng để quản lý giỏ hàng
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Clothing Shop',
        // Cấu hình giao diện (Theme) cho toàn bộ ứng dụng
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            primary: Colors.deepOrange,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        // Màn hình khởi đầu khi mở app là LoginScreen
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
        },
        // Tắt biểu tượng "Debug" ở góc màn hình
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
