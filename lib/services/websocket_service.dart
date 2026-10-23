// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// class WebSocketService {
//   static final WebSocketService _instance = WebSocketService._internal();
//   factory WebSocketService() => _instance;
//   WebSocketService._internal();
//   WebSocketChannel? _channel;
//   bool isConnected = false;
//   String _currentAddress = '';
//   Timer? _reconnectTimer;
//   Timer? _pingTimer;
//   final _connectionController = StreamController<bool>.broadcast();
//   Stream<bool> get connectionStream => _connectionController.stream;
//   static const String defaultDemoDomain = 'wss://saban-demo.onrender.com';
//   bool get _isCloudServer =>
//       _currentAddress.contains('onrender.com') ||
//       _currentAddress.contains('saban-demo');
//   Uri _formatWsUrl(String rawAddress) {
//     String clean = rawAddress.trim().toLowerCase();
//     if (clean.contains('onrender.com') || clean.contains('saban-demo')) {
//       clean = clean
//           .replaceAll('https://', '')
//           .replaceAll('http://', '')
//           .replaceAll('wss://', '')
//           .replaceAll('ws://', '')
//           .replaceAll(':81', '')
//           .replaceAll('/', '');
//       return Uri.parse('wss://$clean'); // BẮT BUỘC wss:// và KHÔNG CÓ :81
//     }
//     if (clean.startsWith('wss://') || clean.startsWith('ws://')) {
//       return Uri.parse(clean);
//     }
//     clean = clean.replaceAll(':81', '').replaceAll('/', '');
//     return Uri.parse('ws://$clean:81');
//   }
//   void connect(String inputAddress) {
//     if (inputAddress.isEmpty) return;
//     _currentAddress = inputAddress.trim();
//     final Uri wsUrl = _formatWsUrl(_currentAddress);
//     _cleanupConnection();
//     try {
//       if (kDebugMode) print('WebSocket: 🔌 Đang kết nối tới $wsUrl...');
//       _channel = WebSocketChannel.connect(wsUrl);
//       _channel!.stream.listen(
//         (message) {
//           if (!isConnected) {
//             isConnected = true;
//             _connectionController.add(true);
//             _startPingTimer();
//             if (kDebugMode) {
//               print('WebSocket: ✅ Kết nối THÀNH CÔNG tới $wsUrl');
//             }
//           }
//           if (kDebugMode) print('WebSocket nhận: $message');
//         },
//         onDone: () {
//           if (kDebugMode) print('WebSocket: Ngắt kết nối (onDone)');
//           _handleDisconnect();
//         },
//         onError: (error) {
//           if (kDebugMode) print('WebSocket lỗi kết nối: $error');
//           _handleDisconnect();
//         },
//       );
//     } catch (e) {
//       if (kDebugMode) print('Lỗi khởi tạo WebSocket: $e');
//       _handleDisconnect();
//     }
//   }
//   void _startPingTimer() {
//     _pingTimer?.cancel();
//     _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (isConnected && _channel != null) {
//         try {
//           if (_isCloudServer) {
//             _channel!.sink.add(jsonEncode({'type': 'ping'}));
//           } else {
//             _channel!.sink.add('PING');
//           }
//         } catch (_) {
//           _handleDisconnect();
//         }
//       }
//     });
//   }
//   void _cleanupConnection() {
//     _pingTimer?.cancel();
//     _reconnectTimer?.cancel();
//     try {
//       _channel?.sink.close();
//     } catch (_) {}
//     _channel = null;
//   }
//   void _handleDisconnect() {
//     bool wasConnected = isConnected;
//     isConnected = false;
//     _cleanupConnection();
//     if (wasConnected) {
//       _connectionController.add(false);
//     }
//     _reconnectTimer = Timer(const Duration(seconds: 3), () {
//       if (!isConnected && _currentAddress.isNotEmpty) {
//         if (kDebugMode) print('WebSocket: Đang tự động kết nối lại...');
//         connect(_currentAddress);
//       }
//     });
//   }
//   void sendSingleRoom(int roomIndex, bool state) {
//     if (!isConnected || _channel == null) {
//       if (kDebugMode) print('WebSocket: Chưa kết nối, không thể gửi lệnh');
//       return;
//     }
//     try {
//       if (_isCloudServer) {
//         final payload = jsonEncode({
//           'hardwareIndex': roomIndex,
//           'state': state,
//           'status': state ? 'ON' : 'OFF'
//         });
//         _channel!.sink.add(payload);
//         if (kDebugMode) print('WebSocket gửi Cloud: $payload');
//       } else {
//         final rawCmd = '$roomIndex:${state ? 1 : 0}';
//         _channel!.sink.add(rawCmd);
//         if (kDebugMode) print('WebSocket gửi LAN: $rawCmd');
//       }
//     } catch (e) {
//       _handleDisconnect();
//     }
//   }
//   void sendGroupRooms(List<int> roomIndexes, bool state) {
//     if (!isConnected || _channel == null || roomIndexes.isEmpty) return;
//     try {
//       if (_isCloudServer) {
//         final payload = jsonEncode({
//           'leds': roomIndexes,
//           'state': state,
//           'status': state ? 'ON' : 'OFF'
//         });
//         _channel!.sink.add(payload);
//         if (kDebugMode) print('WebSocket gửi nhóm Cloud: $payload');
//       } else {
//         final idsString = roomIndexes.join(',');
//         final rawCmd = 'ALL:${state ? 1 : 0}:$idsString';
//         _channel!.sink.add(rawCmd);
//         if (kDebugMode) print('WebSocket gửi nhóm LAN: $rawCmd');
//       }
//     } catch (e) {
//       _handleDisconnect();
//     }
//   }
//   void disconnect() {
//     _currentAddress = '';
//     isConnected = false;
//     _cleanupConnection();
//     _connectionController.add(false);
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool isConnected = false;
  String _currentAddress = '';
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isManualDisconnect = false; // 🟢 Phân biệt ngắt thủ công hay ngắt do sự cố

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  static const String defaultDemoDomain = 'wss://saban-demo.onrender.com';

  bool get _isCloudServer =>
      _currentAddress.contains('onrender.com') ||
      _currentAddress.contains('saban-demo');

  Uri _formatWsUrl(String rawAddress) {
    String clean = rawAddress.trim().toLowerCase();
    if (clean.contains('onrender.com') || clean.contains('saban-demo')) {
      clean = clean
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .replaceAll('wss://', '')
          .replaceAll('ws://', '')
          .replaceAll(':81', '')
          .replaceAll('/', '');
      return Uri.parse('wss://$clean');
    }
    if (clean.startsWith('wss://') || clean.startsWith('ws://')) {
      return Uri.parse(clean);
    }
    clean = clean.replaceAll(':81', '').replaceAll('/', '');
    return Uri.parse('ws://$clean:81');
  }

  void connect(String inputAddress) {
    if (inputAddress.isEmpty) return;

    _isManualDisconnect = false;
    _currentAddress = inputAddress.trim();
    final Uri wsUrl = _formatWsUrl(_currentAddress);

    // 🟢 Hủy kết nối cũ nhưng KHÔNG hủy timer reconnect của lượt mới
    _pingTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    try {
      if (kDebugMode) print('WebSocket: 🔌 Đang kết nối tới $wsUrl...');
      _channel = WebSocketChannel.connect(wsUrl);

      // 🟢 BẬT NGAY TRẠNG THÁI KẾT NỐI & PING DÙ SERVER CHƯA TRẢ TIN NHẮN
      isConnected = true;
      _connectionController.add(true);
      _startPingTimer();

      _channel!.stream.listen(
        (message) {
          if (kDebugMode) print('WebSocket nhận: $message');
        },
        onDone: () {
          if (kDebugMode) print('WebSocket: Ngắt kết nối (onDone)');
          _handleDisconnect();
        },
        onError: (error) {
          if (kDebugMode) print('WebSocket lỗi kết nối: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) print('Lỗi khởi tạo WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    // 🟢 Gửi Ping nhịp tim duy trì Socket mỗi 4 giây
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (isConnected && _channel != null) {
        try {
          if (_isCloudServer) {
            _channel!.sink.add(jsonEncode({'type': 'ping'}));
          } else {
            _channel!.sink.add('PING');
          }
        } catch (e) {
          if (kDebugMode) print('WebSocket Lỗi gửi Ping: $e');
          _handleDisconnect();
        }
      }
    });
  }

  void _handleDisconnect() {
    if (_isManualDisconnect) return; // Nếu chủ động thoát thì không nối lại

    bool wasConnected = isConnected;
    isConnected = false;
    _pingTimer?.cancel();

    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    if (wasConnected) {
      _connectionController.add(false);
    }

    // 🟢 TỰ ĐỘNG RECONNECT SAU 3 GIÂY NẾU BỊ RỚT MẠNG
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!isConnected && _currentAddress.isNotEmpty && !_isManualDisconnect) {
        if (kDebugMode) print('WebSocket: 🔄 Đang tự động kết nối lại tới $_currentAddress...');
        connect(_currentAddress);
      }
    });
  }

  void sendSingleRoom(int roomIndex, bool state) {
    if (!isConnected || _channel == null) {
      if (kDebugMode) print('WebSocket: Chưa kết nối, đang gửi lại...');
      connect(_currentAddress); // Tự nối lại nếu phát hiện mất kết nối khi ấn
      return;
    }
    try {
      if (_isCloudServer) {
        final payload = jsonEncode({
          'hardwareIndex': roomIndex,
          'state': state,
          'status': state ? 'ON' : 'OFF'
        });
        _channel!.sink.add(payload);
        if (kDebugMode) print('WebSocket gửi Cloud: $payload');
      } else {
        final rawCmd = '$roomIndex:${state ? 1 : 0}';
        _channel!.sink.add(rawCmd);
        if (kDebugMode) print('WebSocket gửi LAN: $rawCmd');
      }
    } catch (e) {
      _handleDisconnect();
    }
  }

  void sendGroupRooms(List<int> roomIndexes, bool state) {
    if (!isConnected || _channel == null || roomIndexes.isEmpty) return;
    try {
      if (_isCloudServer) {
        final payload = jsonEncode({
          'leds': roomIndexes,
          'state': state,
          'status': state ? 'ON' : 'OFF'
        });
        _channel!.sink.add(payload);
        if (kDebugMode) print('WebSocket gửi nhóm Cloud: $payload');
      } else {
        final idsString = roomIndexes.join(',');
        final rawCmd = 'ALL:${state ? 1 : 0}:$idsString';
        _channel!.sink.add(rawCmd);
        if (kDebugMode) print('WebSocket gửi nhóm LAN: $rawCmd');
      }
    } catch (e) {
      _handleDisconnect();
    }
  }

  void disconnect() {
    _isManualDisconnect = true; // Đánh dấu ngắt chủ động
    _currentAddress = '';
    isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connectionController.add(false);
  }
}