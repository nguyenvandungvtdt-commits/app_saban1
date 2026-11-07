import 'dart:async';
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
  bool _isManualDisconnect = false;
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  Uri _formatWsUrl(String rawAddress) {
    String clean = rawAddress.trim().toLowerCase();
    clean = clean
        .replaceAll(RegExp(r'https?://|wss?://'), '')
        .replaceAll(RegExp(r':\d+'), '')
        .replaceAll('/', '');
    return Uri.parse('ws://$clean:81');
  }
  Future<bool> connect(String inputAddress) async {
    if (inputAddress.trim().isEmpty) return false;
    _isManualDisconnect = false;
    _currentAddress = inputAddress.trim();
    final Uri wsUrl = _formatWsUrl(_currentAddress);
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    try {
      if (kDebugMode) print('WebSocket: 🔌 Đang thử kết nối tới $wsUrl...');
      final channelCandidate = WebSocketChannel.connect(wsUrl);
      await channelCandidate.ready.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Kết nối quá thời hạn (IP không đúng hoặc không có trong LAN)');
        },
      );
      _channel = channelCandidate;
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
      return true; // Kết nối thành công
    } catch (e) {
      if (kDebugMode) print('❌ [WS ERROR] Không thể kết nối tới $wsUrl: $e');
      isConnected = false;
      _connectionController.add(false);
      _handleDisconnect();
      return false; // Trả về false để UI biết và hiện thông báo lỗi
    }
  }
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (isConnected && _channel != null) {
        try {
          _channel!.sink.add('PING');
        } catch (e) {
          if (kDebugMode) print('WebSocket Lỗi gửi Ping: $e');
          _handleDisconnect();
        }
      }
    });
  }
  void _handleDisconnect() {
    if (_isManualDisconnect) return;
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
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!isConnected && _currentAddress.isNotEmpty && !_isManualDisconnect) {
        if (kDebugMode) print('WebSocket: 🔄 Đang tự động kết nối lại tới $_currentAddress...');
        connect(_currentAddress);
      }
    });
  }
  void sendSingleRoom(int roomIndex, bool state) {
    if (!isConnected || _channel == null) {
      if (kDebugMode) print('WebSocket: Chưa kết nối, đang thử kết nối lại...');
      connect(_currentAddress);
      return;
    }
    try {
      final rawCmd = '$roomIndex:${state ? 1 : 0}';
      _channel!.sink.add(rawCmd);
      if (kDebugMode) print('WebSocket gửi LAN: $rawCmd');
    } catch (e) {
      _handleDisconnect();
    }
  }
  void sendGroupRooms(List<int> roomIndexes, bool state) {
    if (!isConnected || _channel == null || roomIndexes.isEmpty) return;
    try {
      final idsString = roomIndexes.join(',');
      final rawCmd = 'ALL:${state ? 1 : 0}:$idsString';
      _channel!.sink.add(rawCmd);
      if (kDebugMode) print('WebSocket gửi nhóm LAN: $rawCmd');
    } catch (e) {
      _handleDisconnect();
    }
  }
  void disconnect() {
    _isManualDisconnect = true;
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