import 'package:flutter/material.dart';
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
    _navigateToConnectScreen();
  }

  Future<void> _navigateToConnectScreen() async {
    // 🟢 Chờ nhẹ 1 giây hiển thị Splash logo/loading rồi vào trực tiếp ConnectScreen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConnectScreen()),
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