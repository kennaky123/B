import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Màn hình Đăng ký (SignUpScreen)
/// Luồng điều hướng: 
/// - Đến từ: LoginScreen (Màn hình đăng nhập) khi người dùng nhấn "Đăng ký".
/// - Sau khi xong: Quay lại LoginScreen (Navigator.pop) để người dùng đăng nhập bằng tài khoản mới.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Các bộ điều khiển (Controller) để lấy dữ liệu từ các ô nhập liệu (TextField)
  // Các biến controller được gán vào biến html và css ở dưới để xác định ô nhập dữ liệu
  final TextEditingController _usernameController = TextEditingController(); // Nhập Email (Tên đăng nhập)
  final TextEditingController _passwordController = TextEditingController(); // Nhập Mật khẩu
  final TextEditingController _confirmPasswordController = TextEditingController(); // Nhập lại Mật khẩu để xác nhận

  // Biến trạng thái để hiển thị vòng xoay tải dữ liệu (Loading)
  bool _isLoading = false;

  /// Hàm xử lý logic Đăng ký
  void _signup() async {
    // Lấy giá trị từ các ô nhập liệu và xóa khoảng trắng thừa ở đầu/cuối
    String email = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Bước 1: Kiểm tra tính hợp lệ của dữ liệu đầu vào (Validation)
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    // Kiểm tra định dạng email (Yêu cầu phải có đuôi @gmail.com)
    if (!email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên đăng nhập phải có đuôi @gmail.com')),
      );
      return;
    }

    // Kiểm tra độ dài mật khẩu (Tối thiểu 6 ký tự theo yêu cầu của Firebase)
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải dài hơn 6 ký tự')),
      );
      return;
    }

    // Kiểm tra mật khẩu xác nhận có khớp với mật khẩu đã nhập không
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    // Bắt đầu quá trình xử lý, hiển thị hiệu ứng Loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Bước 2: Tạo tài khoản trên Firebase Authentication
      // Thông tin này sẽ được lưu trữ trong hệ thống xác thực của Firebase (Authentication tab)
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Bước 3: Lưu thông tin chi tiết của người dùng vào Cloud Firestore
      // Sau khi tạo tài khoản thành công ở Auth, ta dùng UID (mã định danh duy nhất) 
      // của user đó để tạo một tài liệu (document) trong bộ sưu tập (collection) 'users'.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid) // Dùng UID làm ID của document
          .set({
        'email': email,
        'name': email.split('@')[0], // Lấy phần trước chữ @ làm tên hiển thị mặc định
        'role': 'user',              // Phân quyền mặc định là khách hàng (user)
        'imageUrl': null,            // Ảnh đại diện mặc định là null
      });

      // Tắt trạng thái Loading
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      
      // Thông báo đăng ký thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!')),
      );

      // Bước 4: Điều hướng quay lại màn hình trước đó (LoginScreen)
      // Thông tin tài khoản đã sẵn sàng để đăng nhập.
      Navigator.pop(context);
      
    } on FirebaseAuthException catch (e) {
      // Xử lý các lỗi cụ thể từ Firebase Auth (ví dụ: email đã tồn tại)
      setState(() {
        _isLoading = false;
      });
      String message = 'Đã có lỗi xảy ra';
      if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Xử lý các lỗi hệ thống khác
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
      // Thanh tiêu đề của màn hình
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ô nhập Email
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập (Email @gmail.com)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Ô nhập Mật khẩu
            TextField(
              controller: _passwordController,
              obscureText: true, // Ẩn mật khẩu khi nhập
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Ô xác nhận Mật khẩu
            TextField(
              controller: _confirmPasswordController,
              obscureText: true, // Ẩn mật khẩu khi nhập
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Nút bấm Đăng ký hoặc Vòng quay Loading
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signup, // Gọi hàm _signup khi nhấn nút
                    child: const Text('Đăng ký'),
                  ),
          ],
        ),
      ),
    );
  }
}
