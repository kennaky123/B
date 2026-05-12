import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_navigation.dart';
import 'admin_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình Đăng nhập (LoginScreen)
/// Luồng điều hướng: 
/// - Là màn hình khởi đầu (initialRoute).
/// - Chuyển sang: MainNavigation (nếu là User) hoặc AdminScreen (nếu là Admin).
/// - Có các nút điều hướng tới: SignUpScreen (Đăng ký), ForgotPasswordScreen (Quên mật khẩu).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Bộ điều khiển nhập liệu
  final TextEditingController _usernameController = TextEditingController(); // Thực chất là nhập Email
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false; // Trạng thái hiển thị vòng xoay chờ

  /// Hàm xử lý logic Đăng nhập
  void _login() async {
    String email = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Bước 1: Kiểm tra tính hợp lệ cơ bản
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    if (!email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên đăng nhập phải có đuôi @gmail.com')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải dài hơn 6 ký tự')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Bước 2: Gọi Firebase Authentication để kiểm tra tài khoản
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Bước 3: Sau khi Auth thành công, truy cập Firestore để lấy 'role' (vai trò) của người dùng
      // Thông tin role được lưu trong collection 'users' lúc người dùng đăng ký.
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Bước 4: Điều hướng dựa trên vai trò (Admin hoặc User)
      if (userDoc.exists && userDoc.get('role') == 'admin') {
        // Nếu là Admin -> Chuyển đến màn hình Quản lý
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
      } else {
        // Nếu là User bình thường -> Chuyển đến giao diện mua sắm chính
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý các lỗi đăng nhập phổ biến
      setState(() {
        _isLoading = false;
      });
      String message = 'Sai tên đăng nhập hoặc mật khẩu';
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi hệ thống, vui lòng thử lại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Shop Quần Áo',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập (Email)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            // Nút Quên mật khẩu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 16),
            // Nút Đăng nhập hoặc Vòng quay chờ
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Đăng nhập'),
                  ),
            // Nút chuyển hướng sang Đăng ký
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text('Chưa có tài khoản? Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
