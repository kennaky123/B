import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Màn hình Bản đồ (MapScreen)
/// Chức năng:
/// - Hiển thị địa chỉ thực của cửa hàng.
/// - Cho phép mở ứng dụng bản đồ bên thứ ba (Google Maps, Apple Maps) để dẫn đường.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Địa chỉ của Shop
  final String _shopAddress = "470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng 550000, Việt Nam";

  /// Logic: Mở ứng dụng Bản đồ trên thiết bị
  Future<void> _openGoogleMaps() async {
    // 1. Cố gắng mở trực tiếp ứng dụng bản đồ bằng giao thức 'geo:'
    final String googleMapsUrl = "geo:0,0?q=${Uri.encodeComponent(_shopAddress)}";
    final Uri url = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // 2. Nếu không mở được app (ví dụ trên trình duyệt), mở bằng link web Google Maps
        final String webUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_shopAddress)}";
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Lỗi mở bản đồ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Địa chỉ cửa hàng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Địa chỉ của chúng tôi:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _shopAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map),
                label: const Text('XEM TRÊN GOOGLE MAPS'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '(Nhấn để mở ứng dụng Bản đồ và dẫn đường)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
