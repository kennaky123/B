import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Bạn hãy thay địa chỉ thật của Shop bạn vào đây
  final String _shopAddress = "470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng 550000, Việt Nam";

  Future<void> _openGoogleMaps() async {
    // Dùng geo: để Android mở trực tiếp ứng dụng bản đồ mặc định
    final String googleMapsUrl = "geo:0,0?q=${Uri.encodeComponent(_shopAddress)}";
    final Uri url = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Nếu không mở được bằng link hệ thống, dùng link web thông thường
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
