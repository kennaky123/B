import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final String _myEmail = 'toandq.24itb@vku.udn.vn';
  final String _appPassword = 'vimp vhvt ukmd mnoi';

  String _generateOtp() {
    var random = Random();
    var code = random.nextInt(900000) + 100000; // Tạo mã 6 số từ 100000 đến 999999
    return code.toString();
  }

  Future<void> _sendOtpEmail(String userEmail, String otp) async {
    final smtpServer = gmail(_myEmail, _appPassword);

    final message = Message()
      ..from = Address(_myEmail, 'Hệ thống Xác thực Shop')
      ..recipients.add(userEmail)
      ..subject = 'Mã xác thực bảo mật - $otp'
      ..html = """
        <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
          <h2 style="color: #ff5722;">Bước 1: Xác thực tài khoản</h2>
          <p>Chào bạn, mã xác thực (OTP) để bắt đầu quy trình đặt lại mật khẩu cho tài khoản <b>$userEmail</b> là:</p>
          <div style="background: #f4f4f4; padding: 15px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 10px; color: #333;">
            $otp
          </div>
          <p>Sau khi nhập mã này trên ứng dụng, hệ thống sẽ gửi tiếp một <b>Liên kết đổi mật khẩu chính thức</b> để đảm bảo an toàn tối đa cho bạn.</p>
          <br>
          <p>Trân trọng,<br>Đội ngũ hỗ trợ Shop Quần Áo</p>
        </div>
      """;

    await send(message, smtpServer);
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email của bạn')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otp = _generateOtp();
      await _sendOtpEmail(email, otp);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: email, correctOtp: otp),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi mã OTP: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.mail_lock, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 24),
            const Text(
              'Khôi phục mật khẩu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chúng tôi sẽ gửi hướng dẫn khôi phục đến email của bạn thông qua hệ thống hỗ trợ cá nhân.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email của bạn',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GỬI EMAIL KHÔI PHỤC'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Email hỗ trợ:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              _myEmail,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
