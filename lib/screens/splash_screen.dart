import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connect_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndPrecache();
  }
  Future<void> _initializeAppAndPrecache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedJsonStr = prefs.getString('saved_cloud_config_json');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        Map<String, dynamic> config = jsonDecode(cachedJsonStr);
        await _precacheAllImages(config);
      }
    } catch (e) {
      //
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConnectScreen()),
    );
  }
  Future<void> _precacheAllImages(Map<String, dynamic> config) async {
    List<String> imageUrls = [];
    if (config['assets'] is Map) {
      config['assets'].forEach((key, val) {
        if (val is String && (val.startsWith('http://') || val.startsWith('https://'))) {
          imageUrls.add(val);
        }
      });
    }
    if (config['default_tower_images'] is Map) {
      config['default_tower_images'].forEach((key, val) {
        if (val is String && (val.startsWith('http://') || val.startsWith('https://'))) {
          imageUrls.add(val);
        }
      });
    }
    if (imageUrls.isEmpty) return;
    await Future.wait(
      imageUrls.map((url) => precacheImage(
        CachedNetworkImageProvider(url),
        context,
      ).catchError((err) {
      })),
    );
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0284C7)),
            SizedBox(height: 16),
            Text(
              'Đang khởi động ứng dụng...',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}