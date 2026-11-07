import 'dart:async';
import 'package:flutter/material.dart';
class ReconnectCountdownDialog extends StatefulWidget {
  final String ip;
  final Function(String ip) onReconnect;
  const ReconnectCountdownDialog({
    super.key,
    required this.ip,
    required this.onReconnect,
  });
  @override
  State<ReconnectCountdownDialog> createState() =>
      _ReconnectCountdownDialogState();
}
class _ReconnectCountdownDialogState extends State<ReconnectCountdownDialog> {
  int _secondsLeft = 10; // Đếm ngược 6 giây đủ thời gian ESP32 boot & bắt Wi-Fi
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _startCountdown();
  }
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        Navigator.of(context).pop(); // Đóng Dialog
        widget.onReconnect(widget.ip); // Tự động kết nối lại
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // canPop: false tương đương với onWillPop: () async => false
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Text('Đang khởi động lại...'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Firmware mới đã được nạp thành công. Vui lòng đợi sa bàn khởi động lại và kết nối lại Wi-Fi.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const Text(
                    'Tự động kết nối lại sau vài giây',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop();
              widget.onReconnect(widget.ip);
            },
            child: const Text('Thử kết nối ngay'),
          ),
        ],
      ),
    );
  }
}