import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import '../widgets/interactive_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/buildings_list_screen.dart'; // 🟢 Thay đường dẫn file tương ứng của bạn
import '../services/config_service.dart';
import 'connect_screen.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Để kiểm tra kIsWeb
import '../widgets/dynamic_image.dart';
import '../widgets/image_viewer_dialog.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/image_resolver.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
class MasterControlScreen extends StatefulWidget {
  final MqttServerClient? mqttClient;
  final WebSocketChannel? channel;
  final String ip;
  final String? cachedJson;
  final Map<String, dynamic>? configData;
  final Map<int, bool> ledStates;
  final String currentLang; // 🟢 1. KHAI BÁO THÊM TRƯỜNG NÀY
  const MasterControlScreen({
    super.key,
    required this.ip,
    this.cachedJson,
    this.configData,
    required this.ledStates,
    this.mqttClient,
    this.channel, // 👈 Không dùng required
    this.currentLang = 'vi', // 🟢 2. THÊM VÀO CONSTRUCTOR (Mặc định 'vi')
  });
  @override
  State<MasterControlScreen> createState() => _MasterControlScreenState();
}
class _MasterControlScreenState extends State<MasterControlScreen>
    with SingleTickerProviderStateMixin {
  bool _isHardwareUnresponsive = false;
  bool _hasReceivedHardwareAck = false;
  Timer? _stackingTimer;
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Timer? _heartbeatTimer;
  Animation<Matrix4>? _animation;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  late MqttServerClient _mqttClient;
  StreamSubscription? _mqttSubscription;
  bool isConnected = true;
  Timer? _pingTimer;
  Map<int, bool> _ledStates = {};
  String _projectName = 'Đang tải sa bàn...';
  List<Map<String, dynamic>> _buildings = [];
  Map<String, dynamic> _projectInfo = {};
  final Map<String, dynamic> _configData = {};
  Map<String, dynamic> _dynamicUiConfig = {};
  String _overviewImage = 'assets/images/overview.jpg';
  bool _isLoaded = false;
  bool _isMotorActive = false;
  bool get _isEn => widget.currentLang == 'en';
  bool _isStackingOn = false;
  bool _isRandomOn = false;
  bool _isSparkleOn = false;
  bool _isSinewaveOn = false;
  final String topicResponse = 'saban/response';
  List<Map<String, dynamic>> _enabledEffects = [
    {"cmd": "TOGGLE_STACKLOCK", "name": "XẾP TẦNG", "icon": Icons.air_rounded},
    {"cmd": "TOGGLE_RANDOM", "name": "NGẪU NHIÊN", "icon": Icons.air_rounded},
    {"cmd": "TOGGLE_SPARKLE", "name": "LẤP LÁNH", "icon": Icons.stars_rounded},
    {"cmd": "TOGGLE_SINEWAVE", "name": "SÓNG SIN", "icon": Icons.waves_rounded},
  ];
  String _activeEffect = 'MANUAL';
  double _sparkleSpeed = 350;
  double _randomSpeed = 350;
  double _sineSpeed = 60;
  double _randomDensity = 35;
  double _stackingSpeed = 350;
  void Function(String)? _onModeChangedFromHardware;
  VoidCallback? _onConfigReloadedFromCloud;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      String? savedTitle =
          prefs.getString('saved_connect_title') ??
          prefs.getString('saved_project_name');
      if (savedTitle != null && savedTitle.trim().isNotEmpty && mounted) {
        setState(() {
          _projectName = savedTitle;
        });
      }
    });
    _refreshActiveImage(); // 🟢 Nạp lại và tự động phá cache ảnh active
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
        });
    _loadSavedMotorState();
    _loadSavedLedStates();
    _ledStates = Map<int, bool>.from(widget.ledStates);
    Map<String, dynamic>? configToUse = widget.configData;
    if (configToUse != null &&
        (configToUse.containsKey('d') ||
            configToUse.containsKey('ui_config') ||
            configToUse.containsKey('buildings'))) {
      _dynamicUiConfig = configToUse['ui_config'] ?? {};
      _parseConfigMap(configToUse);
      _isLoaded = true;
    } else if (widget.cachedJson != null && widget.cachedJson!.isNotEmpty) {
      _parseFlatJson(widget.cachedJson!, isFromCache: true);
      _isLoaded = true;
    } else {
      _loadConfigFromLocalCache();
    }
    _ensureAllLedStatesInitialized();
    if (widget.mqttClient != null) {
      _mqttClient = widget.mqttClient!;
      _mqttClient.onAutoReconnected = () {
        if (mounted) {
          setState(() {
            isConnected = true;
          });
        }
        _setupMqttListeners();
      };
      _mqttClient.onDisconnected = () {
        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      };
      _setupMqttListeners();
      isConnected =
          _mqttClient.connectionStatus?.state == MqttConnectionState.connected;
      if (isConnected) {
        _publishMqttCommand('PING');
      }
    } else if (widget.channel != null) {
      _channel = widget.channel;
      _setupWebSocketListeners();
      isConnected = true;
    }
    _startHardwareHeartbeatCheck();
  }
  @override
  void dispose() {
    _pingTimer?.cancel();
    _heartbeatTimer?.cancel();
    _stackingTimer?.cancel();
    _wsSubscription?.cancel();
    _mqttSubscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  String _compressLedIds(List<int> leds) {
    if (leds.isEmpty) return '';
    leds.sort();
    List<String> parts = [];
    int start = leds[0];
    int end = leds[0];
    for (int i = 1; i < leds.length; i++) {
      if (leds[i] == end + 1) {
        end = leds[i];
      } else {
        parts.add(start == end ? '$start' : '$start-$end');
        start = leds[i];
        end = leds[i];
      }
    }
    parts.add(start == end ? '$start' : '$start-$end');
    return parts.join(',');
  }
  List<List<int>> _getFloorsFromBuildingJson() {
    List<List<int>> parallelFloors = [];
    if (_buildings.isEmpty) return parallelFloors;
    int maxFloorsCount = 0;
    for (var b in _buildings) {
      List<dynamic> floors = b['floors'] ?? [];
      if (floors.length > maxFloorsCount) maxFloorsCount = floors.length;
    }
    for (int floorIdx = 0; floorIdx < maxFloorsCount; floorIdx++) {
      Set<int> floorApartmentLeds = {};
      for (var b in _buildings) {
        List<dynamic> floors = b['floors'] ?? [];
        if (floorIdx < floors.length) {
          var f = floors[floorIdx];
          List<dynamic> rooms = f['rooms'] ?? [];
          var apartmentRooms = rooms.where((r) {
            int rType =
                int.tryParse(
                  r['room_type']?.toString() ??
                      r['roomType']?.toString() ??
                      '0',
                ) ??
                0;
            return rType > 0 && rType < 100;
          }).toList();
          floorApartmentLeds.addAll(_extractLeds(apartmentRooms));
        }
      }
      if (floorApartmentLeds.isNotEmpty) {
        List<int> sortedLeds = floorApartmentLeds.toList()..sort();
        parallelFloors.add(sortedLeds);
      }
    }
    return parallelFloors;
  }
  Future<void> _refreshActiveImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String activeProjectId =
        widget.configData?['project_id'] ??
        widget.configData?['projectId'] ??
        widget.configData?['id'] ??
        'dongvancong_1';
    final Map<String, dynamic> projInfo = widget.configData ?? {};
    final String cloudImg =
        projInfo['assets']?['overview'] ??
        projInfo['overview'] ??
        'assets/images/overview.jpg';
    String resolvedPath = await ImageResolver.getActiveImagePath(
      projectId: activeProjectId,
      imageKey: 'master_overview_image',
      cloudUrl: cloudImg,
    );
    final rawSavedImg = prefs.getString('saved_overview_image');
    if (rawSavedImg != null &&
        rawSavedImg.trim().isNotEmpty &&
        rawSavedImg != 'null') {
      bool isAsset = rawSavedImg.startsWith('assets/');
      bool isFileExist = !isAsset && File(rawSavedImg).existsSync();
      if (isAsset || isFileExist) {
        resolvedPath = rawSavedImg;
      } else {
      }
    }
    if (mounted) {
      setState(() {
        _overviewImage = resolvedPath;
      });

    }
  }
  void _startHardwareHeartbeatCheck() {
    _hasReceivedHardwareAck = false;
    _heartbeatTimer?.cancel(); // Hủy timer cũ nếu có
    if (widget.mqttClient != null &&
        _mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      _publishMqttCommand('PING');
    } else if (_channel != null) {
      _sendWsCommand('PING');
    } else {
      return;
    }
    _heartbeatTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_hasReceivedHardwareAck) {
        setState(() {
          _isHardwareUnresponsive = true;
        });
        final bool isMqttMode = widget.mqttClient != null;
        final String msgVi =
            '⚠️ Cảnh báo: ESP32 không phản hồi! Kiểm tra xem ESP32 đã bật đúng giao thức (${isMqttMode ? "MQTT" : "WebSocket"}) chưa.';
        final String msgEn =
            '⚠️ Warning: ESP32 not responding! Ensure ESP32 is in ${isMqttMode ? "MQTT" : "WebSocket"} mode.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.currentLang == 'vi' ? msgVi : msgEn),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }
  void _resetZoomAndExecute(VoidCallback onComplete) {
    if (!_transformationController.value.isIdentity()) {
      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: Matrix4.identity(),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _animationController.forward(from: 0).then((_) {
        onComplete(); // 🟢 Chuyển trang sau khi thu nhỏ xong
      });
    } else {
      onComplete(); // 🟢 Nếu ảnh chưa zoom -> Chuyển trang luôn lập tức!
    }
  }
  void _setupWebSocketListeners() {
    _wsSubscription?.cancel();
    final Stream? broadcastStream = _channel?.stream.asBroadcastStream();
    _wsSubscription = broadcastStream?.listen(
      (message) {
        if (!isConnected && mounted) {
          setState(() => isConnected = true);
        }
        _handleRawIncomingMessage(message.toString().trim());
      },
      onError: (err) {
        if (mounted) _handleDisconnection();
      },
      onDone: () {
        if (mounted) _handleDisconnection();
      },
      cancelOnError: false,
    );
  }
  void _sendWsCommand(String cmd) {
    if (widget.mqttClient != null) {
      _publishMqttCommand(cmd);
    } else if (_channel != null) {
      try {
        _channel?.sink.add(cmd);
      } catch (e) {
        //
      }
    } else {}
  }
  void _publishMqttCommand(String command) {
    if (widget.mqttClient != null &&
        _mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        final String topicCmd =
            widget.configData?['mqtt_topic_pub']?.toString() ??
            'saban/${widget.configData?['project_info']?['project_id'] ?? 'dongvancong_1'}/app_to_esp';
        final builder = MqttClientPayloadBuilder();
        builder.addString(command);
        _mqttClient.publishMessage(
          topicCmd,
          MqttQos.atLeastOnce,
          builder.payload!,
        );
      } catch (e) {
        //
      }
    } else {}
  }
  void _setupMqttListeners() {
    final String activeTopicStatus =
        widget.configData?['mqtt_topic_sub']?.toString() ??
        'saban/${widget.configData?['project_info']?['project_id'] ?? 'dongvancong_1'}/esp_to_app';
    try {
      _mqttClient.subscribe(activeTopicStatus, MqttQos.atLeastOnce);
      _mqttClient.subscribe('saban/pong', MqttQos.atLeastOnce);
      _mqttClient.subscribe('saban/response', MqttQos.atLeastOnce);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_mqttClient.connectionStatus?.state ==
            MqttConnectionState.connected) {
          _publishMqttCommand('GET_STATUS');
        }
      });
    } catch (e) {
      //
    }
    _mqttSubscription?.cancel();
    _mqttSubscription = _mqttClient.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> c) {
        if (c.isEmpty) return;
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        String message = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        ).trim();
        if (message == "OFFLINE") {
          if (mounted) {
            setState(() {
              _isHardwareUnresponsive = true; // Hiện thanh cảnh báo màu cam
            });
          }
          return;
        }
        if (message == "CONNECTED_OK" ||
            message == "ONLINE" ||
            message == "PONG" ||
            message.startsWith("MODE:")) {
          _hasReceivedHardwareAck = true;
          _heartbeatTimer?.cancel();
          if (mounted && _isHardwareUnresponsive) {
            setState(() {
              _isHardwareUnresponsive =
                  false; // Tắt thanh màu cam, chuyển màu XANH
            });
          }
          if (message == "PONG") return;
        }
        if (!isConnected && mounted) {
          setState(() => isConnected = true);
        }
        _handleRawIncomingMessage(message);
      },
      onError: (err) {
        if (mounted) _handleDisconnection();
      },
      onDone: () {
        if (mounted) _handleDisconnection();
      },
      cancelOnError: false,
    );
  }
  void _handleRawIncomingMessage(String message) {
    if (mounted && _isHardwareUnresponsive) {
      setState(() {
        _isHardwareUnresponsive = false;
      });
    }
    _hasReceivedHardwareAck = true;
    _heartbeatTimer?.cancel();
    if (message == 'PONG') {
      return;
    }
    String rawMsg = message.trim();
    if (rawMsg.isEmpty) return;
    List<String> subMessages = rawMsg.contains('|')
        ? rawMsg.split('|')
        : [rawMsg];
    for (String msgItem in subMessages) {
      String msg = msgItem.trim();
      if (msg.isEmpty) continue;
      if (msg.startsWith("MOTOR_STATUS:")) {
        String status = msg.substring(13).trim();
        bool isOn = (status == "ON");
        if (mounted) {
          setState(() {
            _isMotorActive = isOn;
          });
        }
        continue;
      }
      if (msg.startsWith('MODE:')) {
        String activeCmd = msg.substring(5).trim();
        if (mounted) {
          if (_isStackingOn &&
              (activeCmd == "MANUAL" ||
                  activeCmd == "TOGGLE_STACKLOCK" ||
                  activeCmd == "TOGGLE_STACKING")) {
            continue;
          }
          setState(() {
            _activeEffect = activeCmd;
            _isStackingOn =
                (activeCmd == "TOGGLE_STACKLOCK" ||
                activeCmd == "STACKING" ||
                activeCmd == "TOGGLE_STACKING");
            _isRandomOn =
                (activeCmd == "TOGGLE_RANDOM" || activeCmd == "RANDOM");
            _isSparkleOn =
                (activeCmd == "TOGGLE_SPARKLE" || activeCmd == "SPARKLE");
            _isSinewaveOn =
                (activeCmd == "TOGGLE_SINEWAVE" || activeCmd == "SINEWAVE");
          });
          if (_onModeChangedFromHardware != null) {
            _onModeChangedFromHardware!(activeCmd);
          }
        }
        continue;
      }
      if (msg.startsWith('SPEED_STACKLOCK:') ||
          msg.startsWith('SPEED_STACKING:')) {
        final prefixLen = msg.startsWith('SPEED_STACKLOCK:') ? 16 : 15;
        final val = double.tryParse(msg.substring(prefixLen).trim());
        if (val != null && mounted) setState(() => _stackingSpeed = val);
        continue;
      }
      if (msg.startsWith('SPEED_RANDOM:')) {
        final val = double.tryParse(msg.substring(13).trim());
        if (val != null && mounted) setState(() => _randomSpeed = val);
        continue;
      }
      if (msg.startsWith('DENSITY_RANDOM:')) {
        final val = double.tryParse(msg.substring(15).trim());
        if (val != null && mounted) setState(() => _randomDensity = val);
        continue;
      }
      if (msg.startsWith('SPEED_SPARKLE:')) {
        final val = double.tryParse(msg.substring(14).trim());
        if (val != null && mounted) setState(() => _sparkleSpeed = val);
        continue;
      }
      if (msg.startsWith('SPEED_SINEWAVE:')) {
        final val = double.tryParse(msg.substring(15).trim());
        if (val != null && mounted) setState(() => _sineSpeed = val);
        continue;
      }
      if (msg.startsWith('TYPE:')) {
        final parts = msg.split(':');
        if (parts.length >= 3) {
          final int targetType = int.tryParse(parts[1].trim()) ?? -1;
          final bool isOn = parts[2].trim() == '1';
          if (targetType != -1 && mounted) {
            setState(() {
              for (var b in _buildings) {
                for (var f in (b['floors'] as List? ?? [])) {
                  for (var r in (f['rooms'] as List? ?? [])) {
                    int rType = int.tryParse(r['room_type'].toString()) ?? -1;
                    int ledIdx = int.tryParse(r['led_index'].toString()) ?? -1;
                    if (rType == targetType && ledIdx != -1) {
                      _ledStates[ledIdx] = isOn;
                    }
                  }
                }
              }
            });
          }
        }
        continue;
      }
      if (msg.startsWith('ALL:')) {
        final parts = msg.split(':');
        if (parts.length >= 2) {
          final bool isOn = parts[1].trim() == '1';
          if (mounted) {
            setState(() {
              if (parts.length >= 3 && parts[2].trim().isNotEmpty) {
                _ledStates.updateAll((key, value) => false);
                final Set<int> targetIds = _parseCompressedIds(parts[2].trim());
                for (var id in targetIds) {
                  _ledStates[id] = isOn;
                }
              } else {
                _ledStates.updateAll((key, value) => isOn);
              }
            });
          }
        }
        continue;
      }
      if (msg.startsWith('{')) {
        try {
          final Map<String, dynamic> msgJson = jsonDecode(msg);
          if (msgJson.containsKey('status') && msgJson.containsKey('device')) {
            continue;
          }
          if (msgJson.containsKey('d') ||
              msgJson.containsKey('buildings') ||
              msgJson.containsKey('ui_config')) {
            _dynamicUiConfig = msgJson['ui_config'] ?? {};
            _parseConfigMap(msgJson);
            _ensureAllLedStatesInitialized();
          } else {
            _parseFlatJson(msg, isFromCache: false);
            _ensureAllLedStatesInitialized();
          }
        } catch (e) {
          //
        }
        continue;
      }
      if (msg.contains(':')) {
        final parts = msg.split(':');
        if (parts.length == 2) {
          final int? hwIndex = int.tryParse(parts[0].trim());
          final bool isOn = parts[1].trim() == '1';
          if (hwIndex != null && mounted) {
            setState(() {
              _ledStates[hwIndex] = isOn;
            });
          }
        }
      }
    }
  }
  void _ensureAllLedStatesInitialized() {
    int maxIndex = -1;
    for (var b in _buildings) {
      for (var f in (b['floors'] as List? ?? [])) {
        for (var r in (f['rooms'] as List? ?? [])) {
          int ledIdx = int.tryParse(r['led_index'].toString()) ?? -1;
          if (ledIdx != -1) {
            _ledStates.putIfAbsent(ledIdx, () => false);
            if (ledIdx > maxIndex) maxIndex = ledIdx;
          }
        }
      }
    }
    if (maxIndex >= 0) {
      for (int i = 0; i <= maxIndex; i++) {
        _ledStates.putIfAbsent(i, () => false);
      }
    }
  }
  Set<int> _parseCompressedIds(String rawIdsStr) {
    final Set<int> result = {};
    final tokens = rawIdsStr.split(',');
    for (var token in tokens) {
      final cleanToken = token.trim();
      if (cleanToken.contains('-')) {
        final rangeParts = cleanToken.split('-');
        if (rangeParts.length == 2) {
          final int start = int.tryParse(rangeParts[0].trim()) ?? -1;
          final int end = int.tryParse(rangeParts[1].trim()) ?? -1;
          if (start != -1 && end != -1 && start <= end) {
            for (int i = start; i <= end; i++) {
              result.add(i);
            }
          }
        }
      } else {
        final int id = int.tryParse(cleanToken) ?? -1;
        if (id != -1) result.add(id);
      }
    }
    return result;
  }
  Future<void> _saveLedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, bool> stringMap = _ledStates.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      await prefs.setString('saved_led_map_json', jsonEncode(stringMap));
    } catch (e) {
      //
    }
  }
  Future<void> _loadSavedLedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString('saved_led_map_json');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        if (mounted) {
          setState(() {
            decoded.forEach((keyStr, value) {
              int? key = int.tryParse(keyStr);
              if (key != null && value is bool) {
                _ledStates[key] = value;
              }
            });
          });
        }
      }
    } catch (e) {
      //
    }
  }
  Future<void> _saveMotorState(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saved_motor_state', isOn);
  }
  Future<void> _loadSavedMotorState() async {
    final prefs = await SharedPreferences.getInstance();
    bool savedState = prefs.getBool('saved_motor_state') ?? false;
    if (mounted) {
      setState(() {
        _isMotorActive = savedState;
      });
    }
  }
  Future<void> _loadConfigFromLocalCache() async {
    try {
      String? cachedJson = await ConfigService.getSavedJsonConfig();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        cachedJson = cachedJson.replaceAllMapped(
          RegExp(r'/release-([a-zA-Z0-9_]+)'),
          (match) {
            final tagPart = match.group(1)!;
            final fixedTag = tagPart.replaceAllMapped(
              RegExp(r'_([0-9]+)$'),
              (m) => '-${m.group(1)}',
            );
            return '/release-$fixedTag';
          },
        );
        final Map<String, dynamic> loadedMap = jsonDecode(cachedJson);
        _configData.clear();
        _configData.addAll(loadedMap);
        _dynamicUiConfig = _configData['ui_config'] ?? {};
        await _parseConfigMap(_configData);
        _ensureAllLedStatesInitialized();
        return;
      }
    } catch (e) {
      //
    }
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }
  void _toggleMotor(bool value) {
    setState(() {
      _isMotorActive = value;
    });
    _saveMotorState(value); // Lưu lại ngay lập tức
    String command = value ? 'CMD_MOTOR:ON' : 'CMD_MOTOR:OFF';
    try {
      _sendWsCommand(command);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? (_isEn
                        ? 'Magnetic vehicle/train turned ON'
                        : 'Đã bật hệ thống xe/tàu từ trường')
                  : (_isEn
                        ? 'Magnetic vehicle/train STOPPED'
                        : 'Đã dừng hệ thống xe/tàu'),
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: value ? Colors.green : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      //
    }
  }
  Future<void> _parseConfigMap(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    if (!raw.containsKey('flat_rooms') && raw['projects'] is List) {
      final projects = raw['projects'] as List;
      final activeId =
          prefs.getString('last_active_project') ??
          raw['active_project_id']?.toString();
      Map<String, dynamic>? selectedProject;
      for (final item in projects) {
        if (item is! Map) continue;
        final projectInfo = item['project_info'];
        if (projectInfo is! Map) continue;
        final projectId = projectInfo['project_id']?.toString();
        final projectCode = projectInfo['id']?.toString();
        if (projectId == activeId || projectCode == activeId) {
          selectedProject = Map<String, dynamic>.from(item);
          break;
        }
      }
      if (selectedProject == null) {
        return;
      }
      raw = selectedProject;
    }
    final uiConfig = raw['ui'] ?? raw['ui_config'];
    if (uiConfig is Map) {
      _dynamicUiConfig = Map<String, dynamic>.from(uiConfig);
    } else {
      _dynamicUiConfig = {};
    }
    if (!raw.containsKey('d') &&
        !raw.containsKey('buildings') &&
        !raw.containsKey('ui_config') &&
        !raw.containsKey('project_info') &&
        !raw.containsKey('flat_rooms') &&
        !raw.containsKey('room_layouts')) {
      return;
    }
    String projectName = 'Sa Bàn Tòa Nhà';
    Map<String, dynamic> projectInfo = {};
    String overviewImg = 'assets/images/overview.jpg';
    List<Map<String, dynamic>> parsedBuildings = [];
    List<Map<String, dynamic>> parsedEffects = [];
    try {
      if (raw.containsKey('active_effects') && raw['active_effects'] is List) {
        List<dynamic> rawEffects = raw['active_effects'];
        for (var eff in rawEffects) {
          if (eff is Map && eff['enabled'] == true) {
            IconData iconData = Icons.tune_rounded;
            String cmd = eff['cmd'] ?? '';
            if (cmd == 'TOGGLE_EVEN_ODD') iconData = Icons.auto_awesome_rounded;
            if (cmd == 'TOGGLE_METEOR') iconData = Icons.auto_graph_rounded;
            if (cmd == 'TOGGLE_BREATHING') iconData = Icons.air_rounded;
            if (cmd == 'TOGGLE_RANDOM') iconData = Icons.air_rounded;
            if (cmd == 'TOGGLE_SPARKLE') iconData = Icons.stars_rounded;
            if (cmd == 'TOGGLE_SINEWAVE') iconData = Icons.waves_rounded;
            parsedEffects.add({
              'cmd': cmd,
              'name': eff['name'] ?? cmd,
              'icon': iconData,
            });
          }
        }
      }
      projectInfo = raw['project_info'] is Map ? raw['project_info'] : {};
      String? savedConnectTitle = prefs.getString('saved_connect_title');
      String? savedProjectName = prefs.getString('saved_project_name');
      String cloudProjectName =
          projectInfo['name'] ?? raw['p'] ?? 'Sa Bàn Tòa Nhà';
      if (savedConnectTitle != null && savedConnectTitle.trim().isNotEmpty) {
        projectName = savedConnectTitle;
      } else if (savedProjectName != null &&
          savedProjectName.trim().isNotEmpty) {
        projectName = savedProjectName;
      } else {
        projectName = cloudProjectName;
      }
      final String activeProjectId =
          projectInfo['project_id']?.toString() ??
          projectInfo['id']?.toString() ??
          'dongvancong_1';
      String cloudOverviewImg =
          raw['assets']?['overview'] ??
          projectInfo['overview'] ??
          'assets/images/overview.jpg';
      final savedCustomImg = prefs.getString('saved_overview_image');
      if (savedCustomImg != null &&
          savedCustomImg.trim().isNotEmpty &&
          savedCustomImg != 'null' &&
          (savedCustomImg.startsWith('assets/') ||
              File(savedCustomImg).existsSync())) {
        overviewImg = savedCustomImg;
      } else {
        overviewImg = await ImageResolver.getActiveImagePath(
          projectId: activeProjectId,
          imageKey: 'master_overview_image',
          cloudUrl: cloudOverviewImg,
        );

      }
      final roomsData = raw['flat_rooms'] ?? raw['d'] ?? [];
      final List<dynamic> rows = roomsData is List ? roomsData : [];
      Map<String, Map<String, List<Map<String, dynamic>>>> structured = {};
      String parseBuildingName(String rawStr) {
        String clean = rawStr.trim();
        if (clean.isEmpty) return 'THÁP KHÁC';
        String upper = clean.toUpperCase();
        RegExp letterReg = RegExp(r'\b([A-E])\b|([A-E])$');
        Match? match = letterReg.firstMatch(upper);
        if (match != null) {
          String letter = match.group(1) ?? match.group(2) ?? '';
          if (letter.isNotEmpty) return 'THÁP $letter';
        }
        return 'THÁP KHÁC';
      }
      for (var row in rows) {
        String bName = 'THÁP KHÁC';
        String fName = '';
        String rNum = '';
        int rType = 0;
        int ledIdx = 0;
        String rInfo = '';
        if (row is List && row.length >= 5) {
          bName = parseBuildingName(row[0].toString());
          fName = row[1].toString();
          rNum = row[2].toString();
          rType = int.tryParse(row[3].toString()) ?? 0;
          ledIdx = int.tryParse(row[4].toString()) ?? 0;
          rInfo = (row.length > 5)
              ? row[5].toString()
              : (rType >= 100 ? 'Shophouse / Tiện ích' : 'Loại $rType PN');
        } else if (row is Map) {
          bName = parseBuildingName(row['building']?.toString() ?? '');
          fName = row['floor']?.toString() ?? '';
          rNum = row['room_number']?.toString() ?? '';
          rType = int.tryParse(row['room_type']?.toString() ?? '') ?? 0;
          ledIdx = int.tryParse(row['led_index']?.toString() ?? '') ?? 0;
          rInfo =
              row['info']?.toString() ??
              (rType >= 100 ? 'Shophouse / Tiện ích' : 'Loại $rType PN');
        } else {
          continue;
        }
        if (fName.isEmpty || rNum.isEmpty) continue;
        structured.putIfAbsent(bName, () => {});
        structured[bName]!.putIfAbsent(fName, () => []);
        structured[bName]![fName]!.add({
          'room_number': rNum,
          'room_type': rType,
          'led_index': ledIdx,
          'info': rInfo,
        });
      }
      structured.forEach((bName, floorsMap) {
        List<Map<String, dynamic>> floorsList = [];
        floorsMap.forEach((fName, roomsList) {
          floorsList.add({'name': fName, 'rooms': roomsList});
        });
        parsedBuildings.add({'name': bName, 'floors': floorsList});
      });
    } catch (e) {
      //
    }
    if (mounted) {
      setState(() {
        _enabledEffects = parsedEffects.isNotEmpty
            ? parsedEffects
            : _enabledEffects;
        _projectName = projectName;
        _projectInfo = projectInfo;
        _overviewImage =
            overviewImg; // 🟢 Bây giờ _overviewImage đã nhận link Cloud chuẩn
        _buildings = parsedBuildings;
        _isLoaded = true;
      });
      if (_onConfigReloadedFromCloud != null) {
        _onConfigReloadedFromCloud!();
      }
    }
  }
  Future<void> _parseFlatJson(
    String jsonStr, {
    required bool isFromCache,
  }) async {
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      final projects = raw['projects'];
      if (projects is Map) {
        final activeId = raw['active_project_id'];
        debugPrint('🔍 [ACTIVE PROJECT] = ${projects[activeId]}');
      } else if (projects is List) {}
      await _parseConfigMap(raw);
      if (!isFromCache && widget.ip.isNotEmpty) {
        await ConfigService.saveConfig(widget.ip, jsonStr);
      }
    } catch (e) {
      //
    }
  }
  final logger = Logger(printer: PrettyPrinter(methodCount: 0));
  void _resetToConnectScreen() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConnectScreen()),
    );
  }
  List<int> _extractLeds(List<dynamic> roomsList, {int? filterRoomType}) {
    List<int> leds = [];
    for (var r in roomsList) {
      if (r is! Map) continue; // Bỏ qua nếu phần tử không phải Map
      final int rType = int.tryParse(r['room_type']?.toString() ?? '') ?? -1;
      final int? ledIdx = int.tryParse(r['led_index']?.toString() ?? '');
      if (ledIdx != null && ledIdx >= 0) {
        if (filterRoomType == null ||
            filterRoomType == 0 ||
            rType == filterRoomType) {
          leds.add(ledIdx);
        }
      }
    }
    return leds;
  }
  void _handleDisconnection() {
    if (!mounted) return;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    if (isConnected) {
      setState(() {
        isConnected = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('⚠️ Mất kết nối tới Sa bàn. Đang thử nối lại...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _reconnectWebSocket();
  }
  void _reconnectWebSocket() async {
    if (widget.ip.isEmpty) {
      _resetToConnectScreen();
      return;
    }
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || isConnected) return;
    try {
      logger.i(
        '🔄 [WS_RECONNECT] Đang thử khôi phục kết nối tới: ${widget.ip}',
      );
      final cleanHost = widget.ip
          .replaceAll(RegExp(r'https?://|ws://'), '')
          .replaceAll('/', '');
      final uri = Uri.parse('ws://$cleanHost:81');
      final newChannel = WebSocketChannel.connect(uri);
      await newChannel.ready.timeout(const Duration(seconds: 4));
      if (!mounted || isConnected) return;
      _channel = newChannel;
      _wsSubscription = _channel!.stream.listen(
        (data) {
          if (!isConnected && mounted) {
            setState(() => isConnected = true);
          }
          _handleRawIncomingMessage(data.toString().trim());
        },
        onDone: () {
          _handleDisconnection();
        },
        onError: (error) {
          logger.e('⚠️ [WS_ERROR]: Lỗi WebSocket stream: $error');
          _handleDisconnection();
        },
        cancelOnError: true, // Ép ngắt stream khi có lỗi để tránh trigger lặp
      );
      setState(() {
        isConnected = true;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('🟢 Đã khôi phục kết nối tới Sa bàn thành công!'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      logger.w(
        '⚠️ [WS_RECONNECT] Thử lại thất bại ($e). Tự động nối lại sau 3s...',
      );
      if (!mounted || isConnected) return;
      _wsSubscription?.cancel();
      _wsSubscription = null;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !isConnected) {
          _reconnectWebSocket();
        }
      });
    }
  }
  bool _isSendingWsCommand = false;
  void _toggleLedList(List<int> ledIndices, [bool? explicitState]) async {
    if (ledIndices.isEmpty || _isSendingWsCommand) return;
    _isSendingWsCommand = true;
    bool targetState;
    if (explicitState != null) {
      targetState = explicitState;
    } else {
      bool areAllOn = ledIndices.every((idx) => _ledStates[idx] == true);
      targetState = !areAllOn;
    }
    setState(() {
      _activeEffect = 'MANUAL';
      for (int ledIdx in ledIndices) {
        _ledStates[ledIdx] = targetState;
      }
    });
    _saveLedStates();
    _sendWsCommand('MODE:MANUAL');
    await Future.delayed(const Duration(milliseconds: 30));
    List<int> allActiveLedIds = [];
    _ledStates.forEach((id, isOn) {
      if (isOn) allActiveLedIds.add(id);
    });
    if (allActiveLedIds.isEmpty) {
      _sendWsCommand('ALL:0:0');
    } else if (allActiveLedIds.length == 1) {
      _sendWsCommand('${allActiveLedIds.first}:1');
    } else {
      String compressedActiveIds = _compressLedIndices(allActiveLedIds);
      _sendWsCommand('ALL:1:$compressedActiveIds');
    }
    await Future.delayed(const Duration(milliseconds: 150));
    _isSendingWsCommand = false;
  }
  String _compressLedIndices(List<int> indices) {
    if (indices.isEmpty) return "";
    List<int> sorted = List.from(indices)..sort();
    List<String> parts = [];
    int start = sorted[0];
    int end = sorted[0];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        parts.add(start == end ? "$start" : "$start-$end");
        start = sorted[i];
        end = sorted[i];
      }
    }
    parts.add(start == end ? "$start" : "$start-$end");
    return parts.join(',');
  }
  Widget buildOverviewImage(String imagePath) {
    final String validPath = imagePath.trim().isNotEmpty
        ? imagePath
        : 'assets/images/overview.jpg';
    return InteractiveImageViewer(
      key: ValueKey('overview_img_$validPath'),
      imagePath: validPath,
      borderRadius: 20.0,
    );
  }
  void _showQuickEditDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: _projectName,
    );
    final String activeProjectId =
        widget.configData?['project_id'] ??
        widget.configData?['projectId'] ??
        widget.configData?['id'] ??
        'dongvancong_1';
    const String imageKey = 'master_overview_image';
    String previewImagePath = _overviewImage;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: Color(0xFF0369A1)),
                  SizedBox(width: 8),
                  Text(
                    'Cập Nhật Trực Tiếp Sa Bàn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DynamicImage(
                          key: ValueKey('preview_$previewImagePath'),
                          imagePath: previewImagePath,
                          fit: BoxFit.contain,
                          fallbackAsset: 'assets/images/overview.jpg', // 🟢 ĐỔI THÀNH overview.jpg (thay vì building.jpg)
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Dự Án',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (image == null) return;
                            String cleanPath = kIsWeb
                                ? Uri.decodeFull(image.path)
                                : image.path;
                            setDialogState(() {
                              previewImagePath = cleanPath;
                            });
                          } catch (e) {
                            //
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn ảnh từ Thư viện'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    String newName = nameController.text.trim();
                    Map<String, dynamic> projInfo = widget.configData ?? {};
                    String cloudImg =
                        projInfo['assets']?['overview'] ??
                        projInfo['overview'] ??
                        'assets/images/overview.jpg';
                    final prefs = await SharedPreferences.getInstance();
                    if (newName.isNotEmpty) {
                      _projectName = newName;
                      await prefs.setString('saved_project_name', newName);
                    }
                    if (previewImagePath == cloudImg ||
                        previewImagePath == 'null') {
                      await ImageResolver.resetToCloudImage(
                        projectId: activeProjectId,
                        imageKey: imageKey,
                      );
                      await prefs.remove('saved_overview_image');
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      await DefaultCacheManager().emptyCache();
                      if (mounted) {
                        setState(() {
                          _overviewImage = cloudImg;
                        });
                      }

                    } else {

                      await ImageResolver.saveCustomImage(
                        projectId: activeProjectId,
                        imageKey: imageKey,
                        newFilePath: previewImagePath,
                      );
                      await prefs.setString(
                        'saved_overview_image',
                        previewImagePath,
                      );
   
                      if (mounted) {
                        setState(() {
                          _overviewImage = previewImagePath;
                        });
                      }

                    }
   
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Áp Dụng Ngay'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showEffectControlBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            _onModeChangedFromHardware = (newMode) {
              setModalState(() {});
            };
            _onConfigReloadedFromCloud = () {
              setModalState(() {});
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF0284C7),
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'CẤU HÌNH HIỆU ỨNG & TỐC ĐỘ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  ..._enabledEffects.map((eff) {
                    String cmd = eff['cmd'];
                    String title = eff['name'];
                    IconData icon = eff['icon'];
                    double val = 60;
                    double min = 20;
                    double max = 200;
                    String unit = 'ms';
                    if (cmd == 'TOGGLE_SPARKLE') {
                      val = _sparkleSpeed;
                      min = 100;
                      max = 1000;
                      unit = 'ms';
                    } else if (cmd == 'TOGGLE_RANDOM') {
                      val = _randomSpeed;
                      min = 100;
                      max = 3000;
                      unit = 'ms';
                    } else if (cmd == 'TOGGLE_STACKLOCK' || cmd == 'STACKING') {
                      val = _stackingSpeed;
                      min = 100;
                      max = 1000;
                      unit = 'ms';
                    } else if (cmd == 'TOGGLE_SINEWAVE') {
                      val = _sineSpeed;
                      min = 20;
                      max = 200;
                      unit = 'ms';
                    }
                    return _buildCompactEffectRow(
                      title: title,
                      cmd: cmd,
                      icon: icon,
                      value: val,
                      min: min,
                      max: max,
                      unit: unit,
                      setModalState: setModalState,
                      onChanged: (newVal) {
                        setModalState(() {
                          if (cmd == 'TOGGLE_RANDOM') _randomSpeed = newVal;
                          if (cmd == 'TOGGLE_SPARKLE') _sparkleSpeed = newVal;
                          if (cmd == 'TOGGLE_SINEWAVE') _sineSpeed = newVal;
                          if (cmd == 'TOGGLE_STACKLOCK' || cmd == 'STACKING') {
                            _stackingSpeed = newVal;
                          }
                        });
                        setState(() {});
                      },
                      onChangeEnd: (finalVal) {
                        String speedCmd = 'SPEED_RANDOM:${finalVal.toInt()}';
                        if (cmd == 'TOGGLE_RANDOM') {
                          speedCmd = 'SPEED_RANDOM:${finalVal.toInt()}';
                        }
                        if (cmd == 'TOGGLE_STACKLOCK' || cmd == 'STACKING') {
                          speedCmd = 'SPEED_STACKLOCK:${finalVal.toInt()}';
                        }
                        if (cmd == 'TOGGLE_SPARKLE') {
                          speedCmd = 'SPEED_SPARKLE:${finalVal.toInt()}';
                        }
                        if (cmd == 'TOGGLE_SINEWAVE') {
                          speedCmd = 'SPEED_SINEWAVE:${finalVal.toInt()}';
                        }
                        _sendWsCommand(speedCmd);
                      },
                      densityValue: cmd == 'TOGGLE_RANDOM'
                          ? _randomDensity
                          : null,
                      onDensityChanged: cmd == 'TOGGLE_RANDOM'
                          ? (newDensity) {
                              setModalState(() {
                                _randomDensity = newDensity;
                              });
                              setState(() {});
                            }
                          : null,
                      onDensityChangeEnd: cmd == 'TOGGLE_RANDOM'
                          ? (finalDensity) {
                              _sendWsCommand(
                                'DENSITY_RANDOM:${finalDensity.toInt()}',
                              );
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _onModeChangedFromHardware = null;
      _onConfigReloadedFromCloud = null;
    });
  }
  Widget _buildCompactEffectRow({
    required String title,
    required String cmd,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String unit,
    required StateSetter setModalState,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
    double? densityValue,
    ValueChanged<double>? onDensityChanged,
    ValueChanged<double>? onDensityChangeEnd,
  }) {
    bool isActive = false;
    if (cmd == 'TOGGLE_STACKLOCK' || cmd == 'STACKING') {
      isActive = _isStackingOn;
    } else if (cmd == 'TOGGLE_RANDOM' || cmd == 'RANDOM') {
      isActive = _isRandomOn;
    } else if (cmd == 'TOGGLE_SPARKLE' || cmd == 'SPARKLE') {
      isActive = _isSparkleOn;
    } else if (cmd == 'TOGGLE_SINEWAVE' || cmd == 'SINEWAVE') {
      isActive = _isSinewaveOn;
    } else {
      isActive = _activeEffect == cmd;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  bool nextState = !isActive;
                  _stopAllEffects();
                  String targetEffect = nextState ? cmd : 'MANUAL';
                  setModalState(() {
                    _activeEffect = targetEffect;
                    _isStackingOn =
                        (_activeEffect == 'TOGGLE_STACKLOCK' ||
                        _activeEffect == 'STACKING');
                    _isRandomOn =
                        (_activeEffect == 'TOGGLE_RANDOM' ||
                        _activeEffect == 'RANDOM');
                    _isSparkleOn =
                        (_activeEffect == 'TOGGLE_SPARKLE' ||
                        _activeEffect == 'SPARKLE');
                    _isSinewaveOn =
                        (_activeEffect == 'TOGGLE_SINEWAVE' ||
                        _activeEffect == 'SINEWAVE');
                  });
                  setState(() {
                    _activeEffect = targetEffect;
                    _isStackingOn =
                        (_activeEffect == 'TOGGLE_STACKLOCK' ||
                        _activeEffect == 'STACKING');
                    _isRandomOn =
                        (_activeEffect == 'TOGGLE_RANDOM' ||
                        _activeEffect == 'RANDOM');
                    _isSparkleOn =
                        (_activeEffect == 'TOGGLE_SPARKLE' ||
                        _activeEffect == 'SPARKLE');
                    _isSinewaveOn =
                        (_activeEffect == 'TOGGLE_SINEWAVE' ||
                        _activeEffect == 'SINEWAVE');
                  });
                  if (!nextState) {
                    _sendWsCommand('MODE:MANUAL');
                    _sendWsCommand('ALL:0');
                  } else {
                    if (cmd == 'TOGGLE_STACKLOCK' || cmd == 'STACKING') {
                      List<List<int>> rawFloors = _getFloorsFromBuildingJson();
                      if (rawFloors.isNotEmpty) {
                        List<String> formattedFloors = rawFloors
                            .map((ledList) => _compressLedIds(ledList))
                            .toList();
                        String joinedFloors = formattedFloors.join('|');
                        String configPayload = 'STACK_CONFIG:$joinedFloors';
                        _sendWsCommand(configPayload);
                      } else {}
                      _sendWsCommand('MODE:TOGGLE_STACKLOCK');
                    } else {
                      _sendWsCommand('MODE:$cmd');
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                          ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF0369A1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Tốc độ: ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${value.toInt()} $unit',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF0284C7) : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: isActive ? 3.5 : 2.5,
                activeTrackColor: isActive
                    ? const Color(0xFF0284C7)
                    : Colors.grey.shade400,
                inactiveTrackColor: const Color(0xFFE2E8F0),
                thumbColor: isActive
                    ? const Color(0xFF0284C7)
                    : Colors.grey.shade500,
                overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: isActive ? 6.5 : 5.0,
                ),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
          if (densityValue != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            Row(
              children: [
                Icon(
                  Icons.opacity,
                  size: 13,
                  color: isActive
                      ? const Color(0xFF0284C7)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mật độ LED: ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  '${densityValue.toInt()}%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF0284C7) : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: isActive ? 3.5 : 2.5,
                  activeTrackColor: isActive
                      ? const Color(0xFF0284C7)
                      : Colors.grey.shade400,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: isActive
                      ? const Color(0xFF0284C7)
                      : Colors.grey.shade500,
                  overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: isActive ? 6.5 : 5.0,
                  ),
                ),
                child: Slider(
                  value: densityValue,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  onChanged: onDensityChanged,
                  onChangeEnd: onDensityChangeEnd,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  bool _areAllLedsOn(List<int> ledIndices) {
    if (ledIndices.isEmpty) return false;
    for (int ledIdx in ledIndices) {
      if (!(_ledStates[ledIdx] ?? false)) {
        return false;
      }
    }
    return true; // Tất cả LED trong nhóm đều đang BẬT
  }
  List<int> _getAllSabanLeds({int? filterType}) {
    Set<int> uniqueLeds = {};
    if (_buildings.isNotEmpty) {
      for (var b in _buildings) {
        List<dynamic> floors = b['floors'] ?? [];
        for (var f in floors) {
          List<dynamic> rooms = f['rooms'] ?? [];
          if (filterType == null) {
            uniqueLeds.addAll(_extractLeds(rooms));
          } else if (filterType == 0) {
            var apartmentRooms = rooms.where((r) {
              int rType = int.tryParse(r['room_type'].toString()) ?? 0;
              return rType > 0 && rType < 100;
            }).toList();
            uniqueLeds.addAll(_extractLeds(apartmentRooms));
          } else if (filterType == 1000) {
            var utilityRooms = rooms.where((r) {
              int rType = int.tryParse(r['room_type'].toString()) ?? 0;
              return rType >= 100;
            }).toList();
            uniqueLeds.addAll(_extractLeds(utilityRooms));
          } else {
            uniqueLeds.addAll(_extractLeds(rooms, filterRoomType: filterType));
          }
        }
      }
    }
    final rawConfig = widget.configData;
    if (uniqueLeds.isEmpty && rawConfig != null && rawConfig.containsKey('d')) {
      final rawD = rawConfig['d'] as List<dynamic>? ?? [];
      for (var item in rawD) {
        if (item is List && item.length >= 5) {
          int rType = int.tryParse(item[3].toString()) ?? 0;
          int ledIndex = int.tryParse(item[4].toString()) ?? -1;
          if (ledIndex != -1) {
            if (filterType == null) {
              uniqueLeds.add(ledIndex);
            } else if (filterType == 0 && rType > 0 && rType < 100) {
              uniqueLeds.add(ledIndex);
            } else if (filterType == 1000 && rType >= 100) {
              uniqueLeds.add(ledIndex);
            } else if (filterType == rType) {
              uniqueLeds.add(ledIndex);
            }
          }
        }
      }
    }
    List<int> sortedLeds = uniqueLeds.toList()..sort();
    return sortedLeds;
  }
  Widget _buildDynamicControlPanel(
    BuildContext context,
    double screenWidth,
    bool isPhone,
    List<int> allSabanLeds,
    bool isMasterOn,
    Map<String, dynamic> uiLayoutConfig,
  ) {
    List<dynamic> sections = uiLayoutConfig['sections'] ?? [];
    if (sections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 10 : 16,
        vertical: isPhone ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0F2FE).withValues(alpha: 0.92),
            const Color(0xFFF0F9FF).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: InkWell(
              onTap: () {
                _toggleLedList(allSabanLeds);
              },
              onDoubleTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BuildingsListScreen(
                      buildings: _buildings,
                      ledStates: _ledStates,
                      onToggleLeds: _toggleLedList,
                      isAnyLedOn: (List<int> leds) {
                        if (leds.isEmpty) return false;
                        return leds.any((idx) => _ledStates[idx] == true);
                      },
                      extractLeds: _extractLeds,
                      selectedFilterType: 0,
                      configData: widget.configData ?? _configData,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: isPhone ? 6 : 8,
                  horizontal: isPhone ? 20 : 36,
                ),
                decoration: BoxDecoration(
                  gradient: isMasterOn
                      ? const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        ) // Cam (khi cả sa bàn cùng bật)
                      : const LinearGradient(
                          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                        ), // Xanh (khi chưa bật hết)
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMasterOn
                        ? Colors.amberAccent
                        : const Color(0xFF0284C7), // Viền xanh Cyan đậm rõ nét
                    width: isMasterOn
                        ? 2.5
                        : 2.0, // Độ dày viền nổi bật đồng bộ 2.0 - 2.5px
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMasterOn ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: isPhone ? 15 : 17,
                      color: isMasterOn
                          ? Colors.white
                          : const Color(0xFF0369A1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TỔNG SA BÀN (${isMasterOn ? "BẬT" : "TẮT"})',
                      style: TextStyle(
                        fontSize: isPhone ? 11.5 : 13.0,
                        fontWeight: FontWeight.bold,
                        color: isMasterOn
                            ? Colors.white
                            : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isPhone ? 8 : 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(sections.length, (sectionIdx) {
                var section = sections[sectionIdx];
                List<dynamic> rows = section['rows'] ?? [];
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            UnconstrainedBox(
                              child: _buildCommercialButton(
                                label: section['title'] ?? '',
                                filterType: section['master_filter_type'] ?? 0,
                                isPhone: isPhone,
                                isHeaderGroup: true,
                              ),
                            ),
                            SizedBox(height: isPhone ? 6 : 8),
                            ...rows.map((rowItems) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: (rowItems as List).map((btn) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3.0,
                                        ),
                                        child: _buildCommercialButton(
                                          label: btn['label'],
                                          filterType: btn['filter_type'],
                                          isPhone: isPhone,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      if (sectionIdx < sections.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: VerticalDivider(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.4),
                            thickness: 1.2,
                            width: 1,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Chạm 1 lần: Bật/Tắt Căn   |   • Nhấn đúp 2 lần: Danh sách Tòa nhà',
            style: TextStyle(
              fontSize: isPhone ? 8.5 : 10.0,
              color: const Color(0xFF0284C7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCommercialButton({
    required String label,
    required int filterType,
    required bool isPhone,
    bool isHeaderGroup = false,
  }) {
    List<int> ledsOfThisType = _getAllSabanLeds(filterType: filterType);
    bool isTypeOn = _areAllLedsOn(ledsOfThisType);
    return InkWell(
      onTap: () => _toggleLedList(ledsOfThisType, !isTypeOn),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          vertical: isPhone
              ? (isHeaderGroup ? 8 : 6)
              : (isHeaderGroup ? 10 : 8),
          horizontal: isPhone
              ? (isHeaderGroup ? 16 : 10)
              : (isHeaderGroup ? 20 : 14),
        ),
        decoration: BoxDecoration(
          gradient: isTypeOn
              ? const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTypeOn
                ? const Color(
                    0xFF0284C7,
                  ) // Viền xanh Cyan khi bộ lọc đang được kích hoạt
                : const Color(0xFFF472B6), // Viền hồng khi chưa bật
            width: isTypeOn ? 2.5 : 1.0, // Đậm hơn khi bật
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isPhone
                ? (isHeaderGroup ? 11.0 : 10.0)
                : (isHeaderGroup ? 12.5 : 11.0),
            fontWeight: isTypeOn || isHeaderGroup
                ? FontWeight.bold
                : FontWeight.w600,
            color: isTypeOn ? Colors.white : const Color(0xFF831843),
          ),
        ),
      ),
    );
  }
  void _stopAllEffects() {
    _stackingTimer?.cancel();
    setState(() {
      _isStackingOn = false;
      _isRandomOn = false;
      _isSparkleOn = false;
      _isSinewaveOn = false;
    });
  }
  void _showSalesKitModal(BuildContext context) {
    final rawConfig = widget.configData ?? _configData;
    final Map<String, dynamic> projectInfo = Map<String, dynamic>.from(
      rawConfig['project_info'] ?? {},
    );
    final Map<String, dynamic> scaleInfo = Map<String, dynamic>.from(
      projectInfo['scale_info'] ?? {},
    );
    final Map<String, dynamic> salesKit = Map<String, dynamic>.from(
      rawConfig['sales_kit'] ?? {},
    );
    List galleryAlbums = salesKit['gallery_albums'] ?? [];
    final List rawTabs =
        salesKit['tabs'] ??
        [
          {"id": "scale", "title": "Quy Mô", "icon": "domain", "enabled": true},
          {
            "id": "gallery",
            "title": "Thư Viện Ảnh",
            "icon": "photo_library",
            "enabled": true,
          },
        ];
    final activeTabs = rawTabs.where((t) => t['enabled'] == true).toList();
    IconData getTabIcon(String iconName) {
      switch (iconName) {
        case 'domain':
          return Icons.domain_rounded;
        case 'auto_graph':
        case 'photo_library':
          return Icons.photo_library_rounded;
        default:
          return Icons.info_outline_rounded;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_center_rounded,
                      color: Color(0xFF0284C7),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _projectName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _projectInfo['developer'] ??
                                'Chủ đầu tư BĐS Uy Tín',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: DefaultTabController(
                  length: activeTabs
                      .length, // 🟢 Đặt số lượng Tab theo số item đang bật
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFFF8FAFC),
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: const Color(0xFF0284C7),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF0284C7),
                          indicatorWeight: 3,
                          tabs: activeTabs.map<Widget>((tab) {
                            return Tab(
                              icon: Icon(
                                getTabIcon(tab['icon'] ?? ''),
                                size: 20,
                              ),
                              text: tab['title'] ?? '',
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: activeTabs.map<Widget>((tab) {
                            final String tabId = tab['id'] ?? '';
                            switch (tabId) {
                              case 'scale':
                                return ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: scaleInfo.entries.map((entry) {
                                    return _buildScaleCard(
                                      entry.key.toString(),
                                      entry.value.toString(),
                                      Icons.analytics_rounded,
                                    );
                                  }).toList(),
                                );
                              case 'gallery':
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: galleryAlbums.length,
                                  itemBuilder: (context, index) {
                                    var album = galleryAlbums[index];
                                    List photos = album['photos'] ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            album['album_title'] ??
                                                'Album Hình Ảnh',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing: 10,
                                                mainAxisSpacing: 10,
                                                childAspectRatio: 1.3,
                                              ),
                                          itemCount: photos.length,
                                          itemBuilder: (context, photoIdx) {
                                            final String photoPath =
                                                photos[photoIdx]
                                                    .toString()
                                                    .trim();
                                            return GestureDetector(
                                              onTap: () =>
                                                  ImageViewerDialog.show(
                                                    context,
                                                    photoPath,
                                                    title:
                                                        album['album_title'] ??
                                                        'Hình Ảnh Dự Án',
                                                  ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image(
                                                  key: ValueKey(photoPath),
                                                  image: ResizeImage(
                                                    NetworkImage(photoPath),
                                                    width: 500,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade100,
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        child: const Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  },
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildScaleCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0284C7)),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
  Widget _buildTopBar(BuildContext context, bool isPhone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF0369A1),
                size: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'reset') {
                  _resetToConnectScreen();
                } else if (value == 'edit') {
                  _showQuickEditDialog(context);
                } else if (value == 'effects') {
                  _showEffectControlBottomSheet(context);
                } else if (value == 'motor') {
                  _toggleMotor(!_isMotorActive);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'motor',
                  enabled: false, // Chặn tự động đóng menu khi toggle
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter menuSetState) {
                      return Row(
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: _isMotorActive
                                ? const Color(0xFF0284C7)
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isEn
                                  ? 'Vehicle / Maglev Motor'
                                  : 'Mô-tơ Xe/Tàu Từ Trường',
                              style: TextStyle(
                                fontWeight: _isMotorActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _isMotorActive
                                    ? const Color(0xFF0284C7)
                                    : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _isMotorActive, // 👈 Đã đổi thành _isMotorActive
                              activeThumbColor: const Color(0xFF0284C7),
                              activeTrackColor: const Color(0xFF0284C7)
                                  .withAlpha(100),
                              onChanged: (bool newValue) {
                                _toggleMotor(newValue); // Gọi hàm gốc
                                menuSetState(
                                  () {},
                                ); // Cập nhật lại giao diện menu
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'effects',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEn
                            ? 'Effects & Speed Control'
                            : 'Chế độ & Tốc độ Hiệu ứng',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isEn
                              ? 'Edit Name & Image'
                              : 'Chỉnh sửa tên & Ảnh sa bàn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Tự động thêm dấu ... nếu màn hình không đủ rộng
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_disabled_outlined,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isEn
                              ? 'Change IP / Reset Connection'
                              : 'Đổi IP / Đặt lại kết nối',
                          style: const TextStyle(color: Colors.redAccent),
                          overflow: TextOverflow.ellipsis, // Tự cắt bằng dấu ... nếu màn hình quá hẹp
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 12.0 : 20.0,
                    vertical: 7.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_city_rounded,
                          size: 17,
                          color: Color(0xFF0369A1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _projectName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0369A1),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0284C7),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Thông Tin & Tiến Độ Dự Án',
                onPressed: () {
                  _showSalesKitModal(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F9FF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0284C7)),
              const SizedBox(height: 16),
              Text(
                _isEn
                    ? 'Loading latest scale model data...'
                    : 'Đang tải dữ liệu sa bàn mới nhất...',
                style: const TextStyle(
                  color: Color(0xFF0369A1),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final List<int> allSabanLeds = _getAllSabanLeds();
    final bool isMasterOn =
        allSabanLeds.isNotEmpty &&
        allSabanLeds.every((idx) => _ledStates[idx] == true);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DynamicImage(
              imagePath: _overviewImage.trim().isNotEmpty
                  ? _overviewImage
                  : 'assets/images/overview.jpg', // 🟢 Đảm bảo không bị rỗng
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF0F9FF).withValues(alpha: 0.88),
                      const Color(0xFFE0F2FE).withValues(alpha: 0.82),
                      const Color(0xFFF8FAFC).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                bool isPhone = screenWidth < 600;
                String position = _dynamicUiConfig['position'] ?? 'bottom';
                Widget imageWidget = Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 8.0 : 12.0,
                      vertical: isPhone ? 4.0 : 6.0,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          key: ValueKey('gesture_master_$_overviewImage'),
                          behavior: HitTestBehavior
                              .opaque, // Bắt sự kiện trên toàn bộ khung ảnh
                          onHorizontalDragStart: (details) {},
                          onHorizontalDragUpdate: (details) {
                            if (details.delta.dx.abs() > 2) {}
                          },
                          onHorizontalDragEnd: (details) {
                            double velocity = details.primaryVelocity ?? 0;
                            if (velocity < -150) {
                              _resetZoomAndExecute(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuildingsListScreen(
                                      buildings: _buildings,
                                      ledStates: _ledStates,
                                      onToggleLeds: _toggleLedList,
                                      isAnyLedOn: _areAllLedsOn,
                                      extractLeds: _extractLeds,
                                      selectedFilterType: 0,
                                      configData:
                                          widget.configData ?? _configData,
                                      currentLang: widget.currentLang,
                                    ),
                                  ),
                                );
                              });
                            } else if (velocity > 150) {
                              if (Navigator.canPop(context)) {
                                _resetZoomAndExecute(() {
                                  Navigator.pop(context);
                                });
                              }
                            }
                          },
                          child: Container(
                            key: ValueKey('master_container_$_overviewImage'),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: InteractiveImageViewer(
                                key: ValueKey('img_master_$_overviewImage'),
                                imagePath: _overviewImage.trim().isNotEmpty
                                    ? _overviewImage
                                    : 'assets/images/overview.jpg',
                                borderRadius: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                Widget controlPanelWidget = _buildDynamicControlPanel(
                  context,
                  screenWidth,
                  isPhone,
                  allSabanLeds,
                  isMasterOn,
                  _dynamicUiConfig,
                );
                Widget contentBody;
                if (position == 'top') {
                  contentBody = Column(
                    children: [controlPanelWidget, imageWidget],
                  );
                } else if (position == 'left') {
                  contentBody = Row(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.35,
                        child: SingleChildScrollView(child: controlPanelWidget),
                      ),
                      imageWidget,
                    ],
                  );
                } else if (position == 'right') {
                  contentBody = Row(
                    children: [
                      imageWidget,
                      SizedBox(
                        width: screenWidth * 0.35,
                        child: SingleChildScrollView(child: controlPanelWidget),
                      ),
                    ],
                  );
                } else {
                  contentBody = Column(
                    children: [imageWidget, controlPanelWidget],
                  );
                }
                return Column(
                  children: [
                    _buildTopBar(context, isPhone),
                    Expanded(child: contentBody),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
