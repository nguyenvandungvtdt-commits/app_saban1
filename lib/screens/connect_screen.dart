import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dynamic_image.dart'; // 🟢 Dùng DynamicImage widget đa nền tảng
import 'master_control_screen.dart';

import 'dart:io'; // 👈 Thêm dòng này vào đầu file

import '../services/config_service.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../services/sync_service.dart';
import '../services/websocket_service.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../services/image_resolver.dart';

enum WsConnectionStatus {
  disconnected, // 🔴 Đỏ
  connecting, // 🟡 Vàng
  connected, // 🟢 Xanh
}

enum MismatchType { passcode, ip, projectId }

enum ActiveProtocol { mqtt, websocket }

class ConnectScreen extends StatefulWidget {
  final String? autoConnectIp;
  const ConnectScreen({super.key, this.autoConnectIp});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  String _getFreshUrl(String url) {
    if (url.isEmpty) return '';
    final cleanUrl = url.split(RegExp(r'[?&]v=')).first;
    final separator = cleanUrl.contains('?') ? '&' : '?';
    final version = ConfigService.activeSyncVersion.isNotEmpty
        ? ConfigService.activeSyncVersion
        : DateTime.now().millisecondsSinceEpoch.toString();
    return '$cleanUrl${separator}v=$version';
  }

  static bool _isLocalCacheLoaded = false;
  static bool _isCloudSyncGuarded = false;
  final TextEditingController _projectIdController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  ActiveProtocol _currentProtocol =
      ActiveProtocol.websocket; // Mặc định chạy MQTT
  final String broker = 'w621194f.ala.asia-southeast1.emqxsl.com';
  final int port = 8883;
  final String username = 'dangvancongbachloc';
  final String password = 'Anhyeuem12345@';
  String _selectedLang = 'vi';
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.5.102',
  );
  bool _isLoading = false;
  String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
  String _bgImagePath = 'assets/images/background.png';
  String? localDownloadedBinPath;
  bool _isOTAUploading = false;
  bool _isAppInitialized = false;
  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  bool _isSyncingCloud = false;
  String _cloudSyncMessage = '';
  Map<String, dynamic> rawMasterCatalog = {};
  @override
  void initState() {
    super.initState();
    _initData();
    _status = WsConnectionStatus.disconnected;
    _isLoading = false;
    if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
      _ipController.text = widget.autoConnectIp!;
    }
    _loadSavedPreferences();
    _loadSavedLanguage();
    _loadSavedAllSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAppData();
      _checkInitialConnection();
    });
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProjectId =
        prefs.getString('last_active_project') ?? 'dongvancong_1';
    _projectIdController.text = savedProjectId;
    _passcodeController.text =
        prefs.getString('last_active_passcode') ?? '1000';
    String? cachedJsonStr = prefs.getString('saved_cloud_config_json');
    if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
      rawMasterCatalog = jsonDecode(cachedJsonStr);
      _autoFillIpForProject(savedProjectId);
    }
  }

  Future<void> _initializeAppData() async {
    if (_isAppInitialized) {
      return;
    }
    bool hasLocalCache = await _loadFastFromLocalCache();
    if (!hasLocalCache) {
      await _syncCloudData(isManual: false);
    } else {}
    _isAppInitialized = true;
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _passcodeController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String savedIp =
        prefs.getString('active_lan_ip') ??
        prefs.getString('saved_ip') ??
        '192.168.5.102';
    if (savedIp.contains('.local')) {
      savedIp = '192.168.5.102';
    }
    String savedProto =
        prefs.getString('last_working_protocol') ??
        prefs.getString('saved_protocol') ??
        'ws';
    ActiveProtocol protocol = (savedProto == 'mqtt')
        ? ActiveProtocol.mqtt
        : ActiveProtocol.websocket;
    String? lastProject = prefs.getString('last_active_project');
    String? lastPasscode = prefs.getString('last_active_passcode');
    if (!mounted) return;
    setState(() {
      _ipController.text = savedIp;
      _currentProtocol = protocol;
      if (lastProject?.isNotEmpty == true) {
        _projectIdController.text = lastProject!;
      }
      if (lastPasscode?.isNotEmpty == true) {
        _passcodeController.text = lastPasscode!;
      }
    });
  }

  Future<void> _switchEsp32Protocol(String targetProtocol) async {
    String domainOrIp = _ipController.text.trim();
    if (domainOrIp.isEmpty || domainOrIp.contains('.local')) {
      domainOrIp = "192.168.5.102";
    }
    String cleanHost = domainOrIp
        .replaceAll(RegExp(r'https?://|wss?://'), '')
        .replaceAll('/', '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0284C7)),
              const SizedBox(height: 16),
              Text(
                _selectedLang == 'vi'
                    ? 'Đang đổi sang ${targetProtocol.toUpperCase()}...\nThiết bị đang chuyển giao thức (chờ 5s).'
                    : 'Switching to ${targetProtocol.toUpperCase()}...\nRebooting device (wait 5s).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final url = Uri.parse(
        'http://$cleanHost/set-protocol?type=$targetProtocol',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) Navigator.pop(context); // Đóng Dialog Loading
        setState(() {
          _currentProtocol = (targetProtocol == 'mqtt')
              ? ActiveProtocol.mqtt
              : ActiveProtocol.websocket;
          _status = WsConnectionStatus.disconnected;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_working_protocol', targetProtocol);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLang == 'vi'
                  ? '🔄 ESP32 đã chuyển sang ${targetProtocol.toUpperCase()}! Bấm nút "KẾT NỐI VÀ TẢI SA BÀN" bên dưới.'
                  : '🔄 ESP32 switched to ${targetProtocol.toUpperCase()}! Click "CONNECT AND LOAD" below.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (mounted) Navigator.pop(context);
        _showErrorSnackBar('Lỗi ESP32: Status code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar(
        'Không thể gửi lệnh tới $cleanHost. Kiểm tra lại kết nối Wi-Fi.',
      );
    }
  }

  Future<bool> _loadFastFromLocalCache() async {
    final cachedJson = await ConfigService.getSavedJsonConfig();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final bool success = await _loadLocalCachedConfig();
      if (success) {
        _isLocalCacheLoaded = true;
        _isCloudSyncGuarded = true;
        return true;
      }
    }
    _isLocalCacheLoaded = false;
    _isCloudSyncGuarded = false;
    return false;
  }

  Future<void> _applyLocalConfigToUi(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedProjectName = prefs.getString('saved_connect_title');
    String cloudProjectName =
        raw['project_info']?['name'] ?? raw['p'] ?? 'SA BÀN THÔNG MINH';
    // String finalName = cloudProjectName.isNotEmpty
    //     ? cloudProjectName
    //     : (savedProjectName ?? 'SA BÀN THÔNG MINH');
    // 🟢 ƯU TIÊN TÊN ĐÃ ĐỔI TRONG MÁY TRƯỚC
  String finalName = (savedProjectName != null && savedProjectName.trim().isNotEmpty)
      ? savedProjectName
      : cloudProjectName;
    String? cloudBackgroundImg = raw['assets']?['background'];
    String? savedLocalImage = prefs.getString('saved_connect_bg');
    final String versionToUse = ConfigService.activeSyncVersion.isNotEmpty
        ? ConfigService.activeSyncVersion
        : (prefs.getString('last_master_reset_version') ??
              DateTime.now().millisecondsSinceEpoch.toString());
    String finalImg;
    if (cloudBackgroundImg != null && cloudBackgroundImg.trim().isNotEmpty) {
      String cleanUrl = cloudBackgroundImg.trim();
      if (cleanUrl.startsWith('http')) {
        final String baseUrlOnly = cleanUrl.split(RegExp(r'[?&]v=')).first;
        final String separator = baseUrlOnly.contains('?') ? '&' : '?';
        finalImg = '$baseUrlOnly${separator}v=$versionToUse';
      } else {
        finalImg = cleanUrl;
      }
      await prefs.setString('last_cloud_connect_bg', cleanUrl);
      await prefs.setString('saved_connect_bg', finalImg);
    } else if (savedLocalImage != null && savedLocalImage.isNotEmpty) {
      if (savedLocalImage.startsWith('http')) {
        final String baseUrlOnly = savedLocalImage
            .split(RegExp(r'[?&]v='))
            .first;
        final String separator = baseUrlOnly.contains('?') ? '&' : '?';
        finalImg = '$baseUrlOnly${separator}v=$versionToUse';
      } else {
        finalImg = savedLocalImage;
      }
    } else {
      finalImg = 'assets/images/background.png';
    }
    if (mounted) {
      setState(() {
        _appTitle = finalName.toUpperCase();
        _bgImagePath = finalImg;
      });
    }
  }

  Future<bool> _loadLocalCachedConfig() async {
    try {
      final cachedJson = await ConfigService.getSavedJsonConfig();
      if (cachedJson == null || cachedJson.isEmpty) {
        return false;
      }
      final Map<String, dynamic> masterCatalog = jsonDecode(cachedJson);
      final String currentProjectId =
          _projectIdController.text.trim().isNotEmpty
          ? _projectIdController.text.trim()
          : 'dongvancong';
      final String currentPasscode = _passcodeController.text.trim();
      final Map<String, dynamic> activeProjectConfig = _filterProjectCatalog(
        masterCatalog,
        currentProjectId,
        currentPasscode,
      );
      if (activeProjectConfig.isEmpty) {
        return false;
      }
      await _applyLocalConfigToUi(activeProjectConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncCloudData({bool isManual = false}) async {
    if (!isManual && (_isLocalCacheLoaded || _isCloudSyncGuarded)) {
      return;
    }
    if (_isSyncingCloud) {
      return;
    }
    if (mounted) {
      setState(() {
        _isSyncingCloud = true;
        _cloudSyncMessage = _selectedLang == 'vi'
            ? 'Đang đồng bộ Cloud...'
            : 'Syncing Cloud...';
      });
    }
    if (isManual && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedLang == 'vi'
                ? 'Đang tải cấu hình & làm mới bộ nhớ đệm Cloud...'
                : 'Fetching latest Cloud config & clearing cache...',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String rawGistUrl =
        'https://gist.githubusercontent.com/smartscalemodelcontroller-commits/532166906f27c570ff8b0c6890e3fcc2/raw/config.json?t=$timestamp';
    try {
      if (isManual) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await DefaultCacheManager().emptyCache();
      }
      final response = await http
          .get(
            Uri.parse(rawGistUrl),
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final String rawJsonStr = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> rawMasterCatalog = jsonDecode(rawJsonStr);
        await ConfigService.saveConfig(_ipController.text.trim(), rawJsonStr);
        final String currentProjectId =
            _projectIdController.text.trim().isNotEmpty
            ? _projectIdController.text.trim()
            : 'dongvancong';
        final String currentPasscode = _passcodeController.text.trim();
        final Map<String, dynamic> activeProjectConfig = _filterProjectCatalog(
          rawMasterCatalog,
          currentProjectId,
          currentPasscode,
        );
        if (activeProjectConfig.isEmpty) {
          throw Exception('Project Filter Empty');
        }
        await _parseCloudHeaderInfo(activeProjectConfig);
        _isLocalCacheLoaded = true;
        if (mounted) {
          setState(() {
            _isSyncingCloud = false;
            _cloudSyncMessage = _selectedLang == 'vi'
                ? 'Đã đồng bộ Cloud mới nhất'
                : 'Cloud Synced';
          });
        }
        if (isManual && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedLang == 'vi'
                    ? '✅ Đồng bộ Cloud thành công!'
                    : '✅ Cloud Sync complete!',
              ),
            ),
          );
        }
      } else {
        throw Exception('HTTP Code ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncingCloud = false;
        });
      }
      await _loadFastFromLocalCache();
    }
  }

  Future<void> _parseCloudHeaderInfo(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedProjectName = prefs.getString('saved_connect_title');
    String cloudProjectName =
        raw['project_info']?['name'] ?? raw['p'] ?? 'SA BÀN THÔNG MINH';
    // String finalName = cloudProjectName.isNotEmpty
    //     ? cloudProjectName
    //     : (savedProjectName ?? 'SA BÀN THÔNG MINH');
    // 🟢 SỬA TẠI ĐÂY: Ưu tiên tên lưu trong máy trước, nếu không có mới dùng tên từ Cloud JSON
    String finalName =
        (savedProjectName != null && savedProjectName.trim().isNotEmpty)
        ? savedProjectName
        : cloudProjectName;
    String? cloudBackgroundImg = raw['assets']?['background'];
    String? savedLocalImage = prefs.getString('saved_connect_bg');
    final String versionToUse = ConfigService.activeSyncVersion.isNotEmpty
        ? ConfigService.activeSyncVersion
        : (prefs.getString('last_master_reset_version') ??
              DateTime.now().millisecondsSinceEpoch.toString());
    String finalImg;
    if (cloudBackgroundImg != null && cloudBackgroundImg.trim().isNotEmpty) {
      String cleanUrl = cloudBackgroundImg.trim();
      if (cleanUrl.startsWith('http')) {
        final String baseUrlOnly = cleanUrl.split(RegExp(r'[?&]v=')).first;
        final String separator = baseUrlOnly.contains('?') ? '&' : '?';
        finalImg = '$baseUrlOnly${separator}v=$versionToUse';
      } else {
        finalImg = cleanUrl;
      }
      await prefs.setString('last_cloud_connect_bg', cleanUrl);
      await prefs.setString('saved_connect_bg', finalImg);
    } else if (savedLocalImage != null && savedLocalImage.isNotEmpty) {
      if (savedLocalImage.startsWith('http')) {
        final String baseUrlOnly = savedLocalImage
            .split(RegExp(r'[?&]v='))
            .first;
        final String separator = baseUrlOnly.contains('?') ? '&' : '?';
        finalImg = '$baseUrlOnly${separator}v=$versionToUse';
      } else if (kIsWeb || File(savedLocalImage).existsSync()) {
        finalImg = savedLocalImage;
      } else {
        finalImg = 'assets/images/background.png';
      }
    } else {
      finalImg = 'assets/images/background.png';
    }
    if (mounted) {
      setState(() {
        _appTitle = finalName.toUpperCase();
        _bgImagePath = finalImg;
      });
    }
    _autoFillIpForProject(_projectIdController.text);
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'vi';
    if (mounted) {
      setState(() {
        _selectedLang = savedLang;
        _appTitle = _selectedLang == 'vi'
            ? 'ĐIỀU KHIỂN SA BÀN THÔNG MINH'
            : 'SMART SCALE MODEL CONTROLLER';
      });
    }
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedTitle = prefs.getString('saved_connect_title');
    String? savedBg = prefs.getString('saved_connect_bg');
    if (savedBg != null && savedBg.isNotEmpty && savedBg.startsWith('http')) {
      savedBg = _getFreshUrl(savedBg);
    }
    if (mounted) {
      setState(() {
        if (savedTitle != null && savedTitle.isNotEmpty) {
          _appTitle = savedTitle;
        }
        if (savedBg != null && savedBg.isNotEmpty) {
          _bgImagePath = savedBg;
        }
      });
    }
  }

  bool _isValidServerAddress(String input) {
    if (input.trim().isEmpty) return false;
    final clean = input.trim().toLowerCase();
    final ipRegExp = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegExp.hasMatch(clean) ||
        clean.endsWith('.local') ||
        clean.contains('.') ||
        clean.contains('localhost');
  }

  Future<Map<String, dynamic>> _loadRemoteConfigFast({
    String projectId = '',
    String passcode = '',
    bool forceRefresh = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cachedJsonStr = prefs.getString('saved_cloud_config_json');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJsonStr);
          if (decoded is Map<String, dynamic>) {
            rawMasterCatalog = decoded;
            final projectConfig = _filterProjectCatalog(
              rawMasterCatalog,
              projectId,
              passcode,
            );
            _parseCloudHeaderInfo(projectConfig);
            _autoFillIpForProject(projectId);
            return projectConfig;
          }
        } catch (e) {
          //
        }
      }
    }
    final gistRawUrl =
        'https://gist.githubusercontent.com/'
        'smartscalemodelcontroller-commits/'
        '532166906f27c570ff8b0c6890e3fcc2/'
        'raw/config.json?t=${DateTime.now().microsecondsSinceEpoch}';
    try {
      final response = await http
          .get(
            Uri.parse(gistRawUrl),
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        String rawJsonStr = utf8.decode(response.bodyBytes);
        rawJsonStr = rawJsonStr.replaceAllMapped(
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
        final decoded = jsonDecode(rawJsonStr);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Cấu hình Gist không phải JSON object.');
        }
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await DefaultCacheManager().emptyCache();
        final String newSyncVersion = DateTime.now().millisecondsSinceEpoch
            .toString();
        ConfigService.activeSyncVersion = newSyncVersion;
        rawMasterCatalog = decoded;
        await prefs.setString('saved_cloud_config_json', rawJsonStr);
        await prefs.setString('last_master_reset_version', newSyncVersion);
        final projectConfig = _filterProjectCatalog(
          rawMasterCatalog,
          projectId,
          passcode,
        );
        if (mounted) {
          setState(() {
            _parseCloudHeaderInfo(projectConfig);
          });
        } else {
          _parseCloudHeaderInfo(projectConfig);
        }
        _autoFillIpForProject(projectId);
        return projectConfig;
      }
    } catch (e) {
      //
    }
    final cachedJsonStr = prefs.getString('saved_cloud_config_json');
    if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJsonStr);
        if (decoded is Map<String, dynamic>) {
          rawMasterCatalog = decoded;
          final projectConfig = _filterProjectCatalog(
            rawMasterCatalog,
            projectId,
            passcode,
          );
          _parseCloudHeaderInfo(projectConfig);
          _autoFillIpForProject(projectId);
          return projectConfig;
        }
      } catch (e) {
//
      }
    }
    try {
      final localJson = await rootBundle.loadString('assets/config.json');
      final decoded = jsonDecode(localJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'assets/config.json không phải JSON object.',
        );
      }
      rawMasterCatalog = decoded;
      final projectConfig = _filterProjectCatalog(
        rawMasterCatalog,
        projectId,
        passcode,
      );
      _parseCloudHeaderInfo(projectConfig);
      _autoFillIpForProject(projectId);
      return projectConfig;
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _filterProjectCatalog(
    Map<String, dynamic> rawMasterCatalog,
    String projectId,
    String passcode,
  ) {
    final String targetId = projectId.trim().toLowerCase();
    final String targetPasscode = passcode.trim();
    if (targetId.isEmpty || targetPasscode.isEmpty) {
      return {};
    }
    Map<String, dynamic>? getProjectInfo(dynamic project) {
      if (project is! Map) return null;
      final dynamic nestedInfo = project['project_info'];
      if (nestedInfo is Map) {
        return Map<String, dynamic>.from(nestedInfo);
      }
      if (project.containsKey('project_id')) {
        return Map<String, dynamic>.from(project);
      }
      return null;
    }

    bool isValidProject(dynamic project) {
      final info = getProjectInfo(project);
      if (info == null) return false;
      final String savedId = (info['project_id'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final String savedPasscode = (info['passcode'] ?? '').toString().trim();
      return savedId == targetId &&
          savedPasscode.isNotEmpty &&
          savedPasscode == targetPasscode;
    }

    final bool isSingleProject =
        rawMasterCatalog.containsKey('project_info') ||
        rawMasterCatalog.containsKey('project_id');
    if (isSingleProject) {
      if (isValidProject(rawMasterCatalog)) {
        return Map<String, dynamic>.from(rawMasterCatalog);
      }
      return {};
    }
    final dynamic projectsData = rawMasterCatalog['projects'];
    final List<dynamic> projectsList = [];
    if (projectsData is List) {
      projectsList.addAll(projectsData);
    } else if (projectsData is Map) {
      projectsData.forEach((key, value) {
        if (value is Map) {
          final project = Map<String, dynamic>.from(value);
          project.putIfAbsent('project_id', () => key.toString());
          projectsList.add(project);
        }
      });
    }
    for (final project in projectsList) {
      if (isValidProject(project)) {
        return Map<String, dynamic>.from(project as Map);
      }
    }
    return {};
  }

  Future<void> openWebOTAInChrome(String esp32Ip) async {
    if (!_isValidServerAddress(esp32Ip)) {
      _showErrorSnackBar('Địa chỉ IP không hợp lệ!');
      return;
    }
    final Uri url = Uri.parse('http://$esp32Ip/update');
    try {
      if (mounted) {
        setState(() => _isOTAUploading = true);
      }
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _isOTAUploading) {
            setState(() => _isOTAUploading = false);
          }
        });
      } else {
        _resetOtaState(
          'Không mở được URL OTA: $url. '
          'Hãy kiểm tra kết nối Wi-Fi và địa chỉ ESP32.',
        );
      }
    } catch (e) {
      _resetOtaState('Lỗi mở trang OTA: $e');
    }
  }

  void _showSyncOptionsModal(BuildContext context) {
    final syncService = SyncService();
    final isVi = _selectedLang == 'vi';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVi ? "🔄 Tùy Chọn Đồng Bộ Cloud" : "🔄 Cloud Sync Options",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(
                  Icons.table_chart_outlined,
                  color: Colors.blue,
                  size: 26,
                ),
                title: Text(
                  isVi ? "Đồng bộ Sơ đồ & Căn hộ" : "Sync Layout & Rooms",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isVi
                      ? "Tải lại cấu hình JSON từ Gist, giữ nguyên toàn bộ bộ ảnh"
                      : "Reload JSON config from Gist, keep all current images",
                ),
                onTap: () async {
                  Navigator.pop(modalContext);
                  _showLoadingDialog(context);
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  final bool ok = await syncService.syncCleanMasterReset();
                  if (ok) {
                    final freshConfig = await _loadRemoteConfigFast(
                      projectId: _projectIdController.text,
                      passcode: _passcodeController.text,
                      forceRefresh: true,
                    );
                    if (mounted) {
                      setState(() {
                        _parseCloudHeaderInfo(freshConfig);
                      });
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context); // Tắt Loading Dialog
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              ok
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ok
                                    ? (isVi
                                          ? '✅ Đồng bộ sơ đồ & dữ liệu thành công!'
                                          : '✅ Sync completed!')
                                    : (isVi
                                          ? '❌ Đồng bộ thất bại!'
                                          : '❌ Sync failed!'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: ok ? Colors.green : Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _resetOtaState(String errorMsg) {
    if (mounted) {
      setState(() => _isOTAUploading = false);
      _showErrorSnackBar(errorMsg);
    }
  }

  void _connect() async {
    String inputIp = _ipController.text.trim();
    String projectId = _projectIdController.text.trim();
    String passcode = _passcodeController.text.trim();
    if (inputIp.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
      return;
    }
    String cleanAddress = inputIp
        .replaceAll(RegExp(r'https?://|wss?://'), '')
        .replaceAll('/', '');
    if (cleanAddress.contains(':')) {
      cleanAddress = cleanAddress.split(':').first;
    }
    WebSocketService().disconnect();
    final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('saved_cloud_config_json');
    await prefs.setString('saved_ip', cleanAddress);
    await prefs.setString(
      'saved_protocol',
      _currentProtocol == ActiveProtocol.websocket ? 'ws' : 'mqtt',
    );
    setState(() {
      _isLoading = true;
      _status = WsConnectionStatus.connecting;
    });
    try {
      if (_currentProtocol == ActiveProtocol.mqtt) {
        final String clientId =
            'Flutter_App_${DateTime.now().millisecondsSinceEpoch}';
        final client = MqttServerClient.withPort(broker, clientId, port);
        client.secure = true;
        client.securityContext = SecurityContext.defaultContext;
        client.setProtocolV311();
        client.keepAlivePeriod = 20;
        client.connectTimeoutPeriod = 8000;
        client.autoReconnect = true;
        client.resubscribeOnAutoReconnect = true;
        client.pongCallback = () {};
        final connMessage = MqttConnectMessage()
            .withClientIdentifier(clientId)
            .authenticateAs(username, password)
            .startClean();
        client.connectionMessage = connMessage;
        bool isConnected = false;
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            await client.connect();
            if (client.connectionStatus?.state ==
                MqttConnectionState.connected) {
              isConnected = true;
              break;
            }
          } catch (e) {
            client.disconnect();
          }
          if (!isConnected && attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
        if (isConnected) {
          Map<String, dynamic> rawCloudData = {};
          try {
            rawCloudData =
                await _loadRemoteConfigFast(
                  projectId: projectId,
                  passcode: passcode,
                  forceRefresh:
                      true, // 🟢 BẮT BUỘC: Ép tải mới từ Gist & dọn RAM cache
                ).timeout(
                  const Duration(seconds: 8), // 🟢 TĂNG THỜI GIAN: Cho phép tối đa 8 giây để mạng tải đầy đủ JSON
                  onTimeout: () {
                    return <String, dynamic>{};
                  },
                );
          } catch (e) {
            rawCloudData = {};
          }
          Map<String, dynamic> targetProjectConfig = {};
          final String targetInputId = projectId.toLowerCase().trim();
          final String targetInputPass = passcode.trim();
          final dynamic rawProjects = rawCloudData['projects'];
          List<dynamic> projectsList = [];
          if (rawProjects is List) {
            projectsList = rawProjects;
          } else if (rawProjects is Map) {
            projectsList = rawProjects.values.toList();
          }
          if (projectsList.isNotEmpty) {
            for (var p in projectsList) {
              if (p is! Map) continue;
              final info = p['project_info'];
              if (info == null) continue;
              final pId = info['project_id']?.toString().toLowerCase().trim();
              final pCode = info['id']?.toString().toLowerCase().trim();
              if (pId == targetInputId || pCode == targetInputId) {
                targetProjectConfig = Map<String, dynamic>.from(p);
                break;
              }
            }
          } else {
            targetProjectConfig = rawCloudData;
          }
          if (targetProjectConfig.isEmpty) {
            client.disconnect(); // 🟢 Đúng vì ở nhánh MQTT đã khai báo `client`
            _showSecurityErrorDialog(
              'Mã dự án ($projectId) không tồn tại trên hệ thống. Vui lòng kiểm tra lại!',
            );
            return;
          }
          final info =
              targetProjectConfig['project_info'] ?? targetProjectConfig;
          final realPasscode = info['passcode']?.toString().trim();
          if (realPasscode != null && realPasscode != targetInputPass) {
            client.disconnect();
            _showSecurityErrorDialog(
              'Mã PIN (Passcode) không chính xác. Vui lòng kiểm tra lại tài liệu hướng dẫn!',
            );
            return;
          }
          final configLanIp = info['lan_ip']?.toString().trim();
          if (configLanIp != null &&
              configLanIp.isNotEmpty &&
              !configLanIp.endsWith('.local') &&
              configLanIp != cleanAddress) {
            client.disconnect();
            _showSecurityErrorDialog(
              'Địa chỉ IP không trùng khớp với sa bàn này. Vui lòng kiểm tra lại thông tin kết nối!',
            );
            return;
          }
          // 🟢 1. GHI ĐÈ TÊN ĐÃ SỬA VÀO TARGET PROJECT CONFIG
final savedTitle = prefs.getString('saved_connect_title');
if (savedTitle != null && savedTitle.trim().isNotEmpty) {
  if (targetProjectConfig.containsKey('project_info') &&
      targetProjectConfig['project_info'] is Map) {
    targetProjectConfig['project_info']['name'] = savedTitle;
  } else {
    targetProjectConfig['name'] = savedTitle;
  }
}

// 🟢 2. CẬP NHẬT LUÔN TÊN SỬA VÀO RAW CLOUD DATA NẾU CÓ
if (savedTitle != null &&
    savedTitle.trim().isNotEmpty &&
    rawCloudData.isNotEmpty) {
  if (rawCloudData.containsKey('projects')) {
    final dynamic pData = rawCloudData['projects'];
    if (pData is List) {
      for (var p in pData) {
        if (p is Map) {
          final info = p['project_info'];
          if (info != null &&
              (info['project_id'] == projectId || info['id'] == projectId)) {
            info['name'] = savedTitle;
          }
        }
      }
    } else if (pData is Map) {
      pData.forEach((k, v) {
        if (v is Map && (v['project_id'] == projectId || k == projectId)) {
          if (v.containsKey('project_info')) {
            v['project_info']['name'] = savedTitle;
          } else {
            v['name'] = savedTitle;
          }
        }
      });
    }
  }
}


// 🟢 LẤY VÀ KIỂM TRA ẢNH LOCAL/ASSETS TỪ PREFERENCES
final rawSavedOverview = prefs.getString('saved_overview_image') ?? prefs.getString('saved_connect_bg');
String? savedOverview;

if (rawSavedOverview != null && 
    rawSavedOverview.trim().isNotEmpty && 
    rawSavedOverview != 'null') {
  
  bool isAsset = rawSavedOverview.startsWith('assets/');
  bool isFileExist = !isAsset && File(rawSavedOverview).existsSync();
  
  // Nếu là ảnh Assets hoặc File ảnh thực sự có trên máy -> Chấp nhận là ảnh hợp lệ
  if (isAsset || isFileExist) {
    savedOverview = rawSavedOverview;
  }
}

if (savedOverview != null) {
  if (targetProjectConfig.containsKey('assets') && targetProjectConfig['assets'] is Map) {
    targetProjectConfig['assets']['overview'] = savedOverview;
  } else {
    targetProjectConfig['assets'] = {'overview': savedOverview};

  }
} else {
}
          await prefs.setString('last_working_protocol', 'mqtt');
          await prefs.setString(
            'saved_cloud_config_json',
            jsonEncode(targetProjectConfig),
          );
          await prefs.setString('last_active_project', projectId.trim());
          await prefs.setString('last_active_passcode', passcode.trim());
          await prefs.setString('active_lan_ip', cleanAddress);
          await prefs.setBool('is_configured', true);
          if (!mounted) return;
          setState(() {
            _status = WsConnectionStatus.connected;
          });
          // Ghi đè tên đã chỉnh sửa vào config trước khi chuyển màn hình
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MasterControlScreen(
                currentLang: _selectedLang,
                mqttClient: client,
                ip: cleanAddress,
                configData: targetProjectConfig,
                ledStates: const {},
              ),
            ),
          );
        } else {
          client.disconnect();
          if (!mounted) return;
          _showSecurityErrorDialog(
            '❌ Không kết nối được với phần cứng Sa bàn (HiveMQ Cloud)!\nVui lòng kiểm tra nguồn điện ESP32 và kết nối Internet.',
          );
          return; // ⛔ CHẶN KHÔNG CHO VÀO APP
        }
      } else {
        Map<String, dynamic> rawCloudData = {};
        try {
          rawCloudData =
              await _loadRemoteConfigFast(
                projectId: projectId,
                passcode: passcode,
                forceRefresh: true, // Ép tải bản mới nhất từ Gist
              ).timeout(
                const Duration(milliseconds: 5000),
                onTimeout: () {
                  return <String, dynamic>{};
                },
              );
        } catch (e) {
          rawCloudData = {};
        }
        Map<String, dynamic> targetProjectConfig = {};
        final String targetInputId = projectId.toLowerCase().trim();
        final String targetInputPass = passcode.trim();
        final dynamic rawProjects = rawCloudData['projects'];
        List<dynamic> projectsList = [];
        if (rawProjects is List) {
          projectsList = rawProjects;
        } else if (rawProjects is Map) {
          projectsList = rawProjects.values.toList();
        }
        if (projectsList.isNotEmpty) {
          for (var p in projectsList) {
            if (p is! Map) continue;
            final info = p['project_info'];
            if (info == null) continue;
            final pId = info['project_id']?.toString().toLowerCase().trim();
            final pCode = info['id']?.toString().toLowerCase().trim();
            if (pId == targetInputId || pCode == targetInputId) {
              targetProjectConfig = Map<String, dynamic>.from(p);
              break;
            }
          }
        } else {
          targetProjectConfig = rawCloudData;
        }
        if (targetProjectConfig.isEmpty) {
          _showSecurityErrorDialog(
            'Mã dự án ($projectId) không tồn tại trên hệ thống. Vui lòng kiểm tra lại!',
          );
          return;
        }
        final info = targetProjectConfig['project_info'] ?? targetProjectConfig;
        final realPasscode = info['passcode']?.toString().trim();
        if (realPasscode != null && realPasscode != targetInputPass) {
          _showSecurityErrorDialog(
            'Mã PIN (Passcode) không chính xác. Vui lòng kiểm tra lại tài liệu hướng dẫn!',
          );
          return;
        }
        final configLanIp = info['lan_ip']?.toString().trim();
        if (configLanIp != null &&
            configLanIp.isNotEmpty &&
            !configLanIp.endsWith('.local') &&
            configLanIp != cleanAddress) {
          _showSecurityErrorDialog(
            'Địa chỉ IP không trùng khớp với sa bàn này. Vui lòng kiểm tra lại thông tin kết nối!',
          );
          return;
        }
        Uri wsUrl = Uri.parse('ws://$cleanAddress:81');
        WebSocketChannel? channel;
        bool isConnected = false;
        for (int attempt = 1; attempt <= 2; attempt++) {
          try {
            channel = WebSocketChannel.connect(wsUrl);
            await channel.ready.timeout(const Duration(milliseconds: 2500));
            channel.sink.add('SYNC_ALL');
            isConnected = true;
            break;
          } catch (e) {
            isConnected = false;
            try {
              await channel?.sink.close();
            } catch (_) {}
            channel = null;
            if (attempt < 2) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }
        if (isConnected && channel != null) {
  await prefs.setString('last_working_protocol', 'ws');
// 🟢 THÊM ĐOẠN NÀY ĐỂ GIỮ ẢNH CUSTOM KHI KẾT NỐI QUA WEBSOCKET
// 🟢 LẤY VÀ KIỂM TRA ẢNH LOCAL/ASSETS TỪ PREFERENCES
final rawSavedOverview = prefs.getString('saved_overview_image') ?? prefs.getString('saved_connect_bg');
String? savedOverview;

if (rawSavedOverview != null && 
    rawSavedOverview.trim().isNotEmpty && 
    rawSavedOverview != 'null') {
  
  bool isAsset = rawSavedOverview.startsWith('assets/');
  bool isFileExist = !isAsset && File(rawSavedOverview).existsSync();
  
  // Nếu là ảnh Assets hoặc File ảnh thực sự có trên máy -> Chấp nhận là ảnh hợp lệ
  if (isAsset || isFileExist) {
    savedOverview = rawSavedOverview;
  }
}


if (savedOverview != null) {
  if (targetProjectConfig.containsKey('assets') && targetProjectConfig['assets'] is Map) {
    targetProjectConfig['assets']['overview'] = savedOverview;
  } else {
    targetProjectConfig['assets'] = {'overview': savedOverview};
  }
} else {
}

  // 🟢 1. GHI ĐÈ TÊN ĐÃ SỬA VÀO TARGET PROJECT CONFIG
  final savedTitle = prefs.getString('saved_connect_title');
  if (savedTitle != null && savedTitle.trim().isNotEmpty) {
    if (targetProjectConfig.containsKey('project_info') &&
        targetProjectConfig['project_info'] is Map) {
      targetProjectConfig['project_info']['name'] = savedTitle;
    } else {
      targetProjectConfig['name'] = savedTitle;
    }
  }

  // 🟢 2. CẬP NHẬT TÊN SỬA VÀO RAW CLOUD DATA NẾU CÓ
  if (savedTitle != null &&
      savedTitle.trim().isNotEmpty &&
      rawCloudData.isNotEmpty) {
    if (rawCloudData.containsKey('projects')) {
      final dynamic pData = rawCloudData['projects'];
      if (pData is List) {
        for (var p in pData) {
          if (p is Map) {
            final info = p['project_info'];
            if (info != null &&
                (info['project_id'] == projectId || info['id'] == projectId)) {
              info['name'] = savedTitle;
            }
          }
        }
      } else if (pData is Map) {
        pData.forEach((k, v) {
          if (v is Map && (v['project_id'] == projectId || k == projectId)) {
            if (v.containsKey('project_info')) {
              v['project_info']['name'] = savedTitle;
            } else {
              v['name'] = savedTitle;
            }
          }
        });
      }
    }
  }


  // 🟢 3. LƯU LẠI DỮ LIỆU ĐÃ ĐƯỢC ĐỔI TÊN VÀO PREFERENCES
  if (rawCloudData.isNotEmpty) {
    await prefs.setString(
      'saved_cloud_config_json',
      jsonEncode(rawCloudData),
    );
  } else {
    await prefs.setString(
      'saved_cloud_config_json',
      jsonEncode(targetProjectConfig),
    );
  }

  await prefs.setString('last_active_project', projectId.trim());
  await prefs.setString('last_active_passcode', passcode.trim());
  await prefs.setString('active_lan_ip', cleanAddress);
  await prefs.setBool('is_configured', true);

  if (!mounted) return;
  setState(() {
    _status = WsConnectionStatus.connected;
  });

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MasterControlScreen(
        currentLang: _selectedLang,
        channel: channel,
        ip: cleanAddress,
        configData: targetProjectConfig,
        ledStates: const {},
      ),
    ),
  );
} else {
          try {
            await channel?.sink.close();
          } catch (_) {}
          if (!mounted) return;
          _showSecurityErrorDialog(
            '❌ Không kết nối được tới phần cứng Sa bàn LAN ($cleanAddress:81)!\nVui lòng đảm bảo mạch ESP32 đã bật nguồn và máy bắt cùng Wi-Fi.',
          );
          return; // ⛔ CHẶN KHÔNG CHO VÀO APP
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Đã xảy ra lỗi hệ thống khi xử lý kết nối!');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSecurityErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text(
              'Xác thực thất bại',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu & Kiểm tra lại'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImageEditDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController(
      text: _appTitle,
    );
    final String activeProjectId = _projectIdController.text.trim().isEmpty
        ? 'default_project'
        : _projectIdController.text.trim();
    const String imageKey = 'connect_bg';
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
                  Icon(Icons.edit_note_rounded, color: Color(0xFF0369A1)),
                  SizedBox(width: 10),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _bgImagePath.startsWith('http')
                            ? Image.network(
                                _bgImagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : (_bgImagePath.startsWith('assets/')
                                  ? Image.asset(_bgImagePath, fit: BoxFit.cover)
                                  : (kIsWeb || File(_bgImagePath).existsSync()
                                        ? Image.file(
                                            File(_bgImagePath),
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image_not_supported_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Tên Dự Án',
                              prefixIcon: Icon(Icons.business_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Tooltip(
                        //   message: 'Khôi phục tên gốc',
                        //   child: IconButton.filledTonal(
                        //     style: IconButton.styleFrom(
                        //       backgroundColor: Colors.orange.shade50,
                        //       foregroundColor: Colors.orange.shade800,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //       padding: const EdgeInsets.all(12),
                        //     ),
                        //     onPressed: () async {
                        //       try {
                        //         final prefs =
                        //             await SharedPreferences.getInstance();
                        //         await prefs.remove('saved_connect_title');
                        //         final Map<String, dynamic> projectConfig =
                        //             _filterProjectCatalog(
                        //               rawMasterCatalog,
                        //               activeProjectId,
                        //               _passcodeController.text.trim(),
                        //             );
                        //         String defaultTitle =
                        //             projectConfig['project_info']?['name'] ??
                        //             projectConfig['p'] ??
                        //             'SA BÀN THÔNG MINH';
                        //         titleController.text = defaultTitle
                        //             .toUpperCase();
                        //         if (mounted) {
                        //           setState(() {
                        //             _appTitle = defaultTitle.toUpperCase();
                        //           });
                        //         }
                        //         setDialogState(() {});
                        //       } catch (_) {}
                        //     },
                        //     icon: const Icon(Icons.undo_rounded, size: 20),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                            await ImageResolver.saveCustomImage(
                              projectId: activeProjectId,
                              imageKey: imageKey,
                              newFilePath: cleanPath,
                            );
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'saved_connect_bg',
                              cleanPath,
                            );
                            if (mounted) {
                              setState(() {
                                _bgImagePath = cleanPath;
                              });
                            }
                            setDialogState(() {});
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Chọn ảnh từ Thư viện'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 10),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () async {
                    //       try {
                    //         await ImageResolver.resetToCloudImage(
                    //           projectId: activeProjectId,
                    //           imageKey: imageKey,
                    //         );
                    //         final prefs = await SharedPreferences.getInstance();
                    //         await prefs.remove('saved_connect_bg');
                    //         if (mounted) {
                    //           setState(() {
                    //             _bgImagePath = 'assets/images/background.png';
                    //           });
                    //         }
                    //         setDialogState(() {});
                    //         await _loadRemoteConfigFast();
                    //         if (dialogContext.mounted) {
                    //           Navigator.pop(dialogContext);
                    //         }
                    //         if (context.mounted) {
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(
                    //               content: Text(
                    //                 'Đã khôi phục ảnh gốc từ Cloud!',
                    //               ),
                    //               duration: Duration(seconds: 2),
                    //             ),
                    //           );
                    //         }
                    //       } catch (_) {}
                    //     },
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.orange,
                    //       side: const BorderSide(color: Colors.orange),
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //     ),
                    //     icon: const Icon(Icons.refresh_rounded, size: 20),
                    //     label: const Text(
                    //       'Khôi phục ảnh gốc từ Cloud',
                    //       style: TextStyle(fontWeight: FontWeight.bold),
                    //     ),
                    //   ),
                    // ),
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
                    try {
                      String newTitle = titleController.text.trim();
                      final prefs = await SharedPreferences.getInstance();
                      if (newTitle.isNotEmpty) {
                        await prefs.setString('saved_connect_title', newTitle);
                        if (mounted) {
                          setState(() {
                            _appTitle = newTitle;
                          });
                        }
                      }
                    } catch (_) {
                    } finally {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF0F9FF),
                  Color(0xFFE0F2FE),
                  Color(0xFFF8FAFC),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: DynamicImage(
                            key: ValueKey(
                              _bgImagePath,
                            ), // 🟢 THÊM KEY NÀY ĐỂ ÉP RE-RENDER KHI ĐỔI URL
                            imagePath: _bgImagePath,
                            fit: BoxFit.contain,
                            fallbackAsset: 'assets/images/background.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 18.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFBAE6FD),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7)
                              .withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF0369A1),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _appTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildConnectionBadge(), // Badge kết nối phần cứng ESP32
                            const SizedBox(width: 8),
                            _buildCloudSyncBadge(), // 🟢 Badge trạng thái đồng bộ dữ liệu Cloud
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            labelText: _selectedLang == 'vi'
                                ? 'Địa chỉ IP / Server Sa bàn'
                                : 'IP Address / Model Server',
                            labelStyle: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 13,
                            ),
                            hintText: _selectedLang == 'vi'
                                ? 'Ví dụ: 192.168.5.102'
                                : 'e.g., 192.168.5.102',
                            prefixIcon: const Icon(
                              Icons.wifi_rounded,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0284C7),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _projectIdController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          onChanged: (value) => _autoFillIpForProject(value),
                          decoration: InputDecoration(
                            labelText: _selectedLang == 'vi'
                                ? 'Mã dự án (Project ID)'
                                : 'Project ID',
                            labelStyle: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 13,
                            ),
                            hintText: _selectedLang == 'vi'
                                ? 'Ví dụ: dongvancong'
                                : 'e.g., dongvancong',
                            prefixIcon: const Icon(
                              Icons.business_rounded,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0284C7),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Khoảng cách giữa các ô
                        TextField(
                          controller: _passcodeController,
                          obscureText: false, // 🟢 Đổi thành false để hiển thị rõ Passcode
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            labelText: _selectedLang == 'vi'
                                ? 'Mã PIN bảo mật (Passcode)'
                                : 'Security Passcode',
                            labelStyle: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 13,
                            ),
                            hintText: '1234', // 🟢 Đổi '****' thành gợi ý dạng số dễ nhìn
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFBAE6FD),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0284C7),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: InkWell(
                            onTap: _isLoading ? null : _connect,
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF94A3B8),
                                          Color(0xFF64748B),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF0284C7),
                                          Color(0xFF0369A1),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _selectedLang == 'vi'
                                                ? 'Đang kết nối, vui lòng chờ chút ạ!'
                                                : 'Connecting, please wait...',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.power_settings_new_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedLang == 'vi'
                                                ? 'KẾT NỐI VÀ TẢI SA BÀN'
                                                : 'CONNECT & LOAD SCALE MODEL',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isSyncingCloud
            ? const Color(0xFF0284C7).withValues(alpha: .1)
            : const Color(0xFF10B981).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSyncingCloud
              ? const Color(0xFF0284C7).withValues(alpha: .4)
              : const Color(0xFF10B981).withValues(alpha: .4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isSyncingCloud
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF0284C7),
                  ),
                )
              : const Icon(
                  Icons.cloud_done_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
          const SizedBox(width: 6),
          Text(
            _cloudSyncMessage.isEmpty
                ? (_selectedLang == 'vi' ? 'Sẵn sàng' : 'Ready')
                : _cloudSyncMessage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isSyncingCloud
                  ? const Color(0xFF0284C7)
                  : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
              icon: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF0369A1),
                size: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) async {
                if (value == 'sync_cloud') {
                  _showSyncOptionsModal(context);
                } else if (value == 'set_esp_mqtt') {
                  await _switchEsp32Protocol('mqtt');
                } else if (value == 'set_esp_ws') {
                  await _switchEsp32Protocol('ws');
                } else if (value == 'edit_image') {
                  _showImageEditDialog(context);
                } else if (value == 'open_chrome_ota') {
                  openWebOTAInChrome(_ipController.text.trim());
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'sync_cloud',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_sync_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Đồng bộ lại dữ liệu Cloud'
                              : 'Re-sync Cloud Data',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final bool isWs =
                          (_currentProtocol == ActiveProtocol.websocket);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLang == 'vi'
                                ? 'Giao thức ESP32:'
                                : 'ESP32 Protocol:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final targetProtocolStr = isWs ? 'mqtt' : 'ws';
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'last_working_protocol',
                                targetProtocolStr,
                              );
                              menuSetState(() {
                                _currentProtocol = isWs
                                    ? ActiveProtocol.mqtt
                                    : ActiveProtocol.websocket;
                              });
                              if (mounted) {
                                setState(() {}); // Cập nhật UI bên ngoài
                              }
                              await _switchEsp32Protocol(targetProtocolStr);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 100,
                              height: 32,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isWs
                                    ? const Color(0xFF0284C7)
                                          .withValues(alpha: 0.15)
                                    : Colors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isWs
                                      ? const Color(0xFF0284C7)
                                      : Colors.purple,
                                  width: 1.2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'WS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0284C7),
                                            ),
                                          ),
                                          Text(
                                            'MQTT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedAlign(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    alignment: isWs
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Container(
                                      width: 46,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isWs
                                            ? const Color(0xFF0284C7)
                                            : Colors.purple,
                                        borderRadius: BorderRadius.circular(13),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          isWs ? 'WS' : 'MQTT',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'edit_image',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF0369A1),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Chỉnh Sửa Tiêu Đề / Ảnh'
                              : 'Edit Title / Image',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'open_chrome_ota',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chrome_reader_mode_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Mở Trang Nạp OTA Trên Trình Duyệt'
                              : 'Open OTA Page in Browser',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final newLang = (_selectedLang == 'vi') ? 'en' : 'vi';
                  if (mounted) {
                    setState(() {
                      _selectedLang = newLang;
                      _appTitle = _selectedLang == 'vi'
                          ? 'ĐIỀU KHIỂN SA BÀN THÔNG MINH'
                          : 'SMART SCALE MODEL CONTROLLER';
                    });
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', newLang);
                },
                child: Container(
                  width: 96,
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Opacity(
                                opacity: 0.3,
                                child: Text(
                                  'VN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: 0.3,
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _selectedLang == 'vi'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: 50,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.25),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedLang == 'vi' ? '🇻🇳' : '🇬🇧',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _selectedLang == 'vi' ? 'VN' : 'EN',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF0369A1),
                    size: 22,
                  ),
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: _appTitle,
                      applicationVersion: 'v1.0.2',
                      applicationIcon: const Icon(
                        Icons.domain_rounded,
                        color: Color(0xFF0284C7),
                        size: 36,
                      ),
                      children: [
                        Text(
                          _selectedLang == 'vi'
                              ? 'Ứng dụng điều khiển sa bàn thông minh kết nối qua mạng LAN/Cloud.'
                              : 'Smart scale model control application via LAN/Cloud connection.',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _autoFillIpForProject(dynamic input) {
    String targetId = '';
    if (input is String) {
      targetId = input.trim();
    } else if (input is Map) {
      final info = input['project_info'] ?? input;
      targetId =
          (info['project_id'] ??
                  input['project_id'] ??
                  _projectIdController.text)
              .toString()
              .trim();
    } else {
      targetId = _projectIdController.text.trim();
    }
    if (targetId.isEmpty) return;
    String? foundIp;
    if (rawMasterCatalog.isNotEmpty) {
      final targetConfig = _filterProjectCatalog(
        rawMasterCatalog,
        targetId,
        _passcodeController.text,
      );
      final info = targetConfig['project_info'] ?? targetConfig;
      final parsedIp =
          info['lan_ip']?.toString() ?? targetConfig['lan_ip']?.toString();
      if (parsedIp != null &&
          parsedIp.isNotEmpty &&
          !parsedIp.endsWith('.local')) {
        foundIp = parsedIp.trim();
      }
    }
    if (_ipController.text.trim().isEmpty && foundIp != null) {
      final String nonNullIp = foundIp;
      setState(() {
        _ipController.text = nonNullIp;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('saved_ip', nonNullIp);
        prefs.setString('active_lan_ip', nonNullIp);
      });
    } else {}
  }

  Future<void> _checkInitialConnection() async {
    if (_isLoading || _status == WsConnectionStatus.connecting) return;
    if (mounted) {
      setState(() {
        _status = WsConnectionStatus.connecting;
      });
    }
    if (_currentProtocol == ActiveProtocol.websocket) {
      final activeId = _projectIdController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> currentCatalog = rawMasterCatalog;
      if (currentCatalog.isEmpty) {
        String? cachedJsonStr = prefs.getString('saved_cloud_config_json');
        if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
          try {
            currentCatalog = jsonDecode(cachedJsonStr);
          } catch (_) {}
        }
      }
      String domainOrIp = '';
      if (currentCatalog.isNotEmpty) {
        final targetConfig = _filterProjectCatalog(
          currentCatalog,
          activeId,
          _passcodeController.text,
        );
        final info = targetConfig['project_info'] ?? targetConfig;
        domainOrIp =
            info['lan_ip']?.toString() ??
            targetConfig['lan_ip']?.toString() ??
            '';
      }
      if (domainOrIp.isEmpty) {
        domainOrIp = _ipController.text.trim();
      } else {
        if (_ipController.text != domainOrIp && mounted) {
          setState(() {
            _ipController.text = domainOrIp;
          });
        }
      }
      if (domainOrIp.isEmpty || domainOrIp.contains('.local')) {
        if (mounted) {
          setState(() {
            _status = WsConnectionStatus.disconnected;
          });
        }
        return;
      }
      String cleanHost = domainOrIp
          .replaceAll(RegExp(r'https?://|wss?://'), '')
          .replaceAll(RegExp(r':\d+'), '')
          .replaceAll('/', '');
      bool wsAvailable = false;
      try {
        final socket = await Socket.connect(
          cleanHost,
          81,
          timeout: const Duration(milliseconds: 2500),
        );
        wsAvailable = true;
        await socket.close();
      } catch (e) {
        wsAvailable = false;
      }
      if (mounted) {
        setState(() {
          _status = wsAvailable
              ? WsConnectionStatus.connected
              : WsConnectionStatus.disconnected;
        });
      }
      return; // Dừng tại đây nếu là WebSocket
    }
    final currentProjectId = _projectIdController.text.trim().toLowerCase();
    final String topicCmd = 'saban/$currentProjectId/app_to_esp';
    final String topicStatus = 'saban/$currentProjectId/esp_to_app';
    bool espIsOnline = false;
    final String clientId =
        'Flutter_Check_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(broker, clientId, port);
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.setProtocolV311();
    client.keepAlivePeriod = 10;
    client.connectTimeoutPeriod = 3000;
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean();
    client.connectionMessage = connMessage;
    StreamSubscription? subscription;
    try {
      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        Completer<bool> espResponseCompleter = Completer<bool>();
        client.subscribe(topicStatus, MqttQos.atMostOnce);
        subscription = client.updates?.listen((messages) {
          final recMess = messages[0].payload as MqttPublishMessage;
          final pt = MqttPublishPayload.bytesToStringAsString(
            recMess.payload.message,
          );
          if (pt.contains("ESP32_READY") ||
              pt.contains("CONNECTED_OK") ||
              pt.contains("PONG") ||
              pt.contains("ONLINE")) {
            if (!espResponseCompleter.isCompleted) {
              espResponseCompleter.complete(true);
            }
          }
        });
        final builder = MqttClientPayloadBuilder();
        builder.addString('PING');
        client.publishMessage(topicCmd, MqttQos.atMostOnce, builder.payload!);
        try {
          espIsOnline = await espResponseCompleter.future.timeout(
            const Duration(milliseconds: 2500),
          );
        } catch (_) {
          espIsOnline = false;
        }
      }
    } catch (e) {
//
    } finally {
      await subscription?.cancel();
      client.disconnect();
    }
    if (mounted) {
      setState(() {
        _status = espIsOnline
            ? WsConnectionStatus.connected
            : WsConnectionStatus.disconnected;
      });
    }
  }

  Widget _buildConnectionBadge() {
    Color color;
    String text;
    IconData icon;
    final bool isMqtt = (_currentProtocol == ActiveProtocol.mqtt);
    final bool isVi = (_selectedLang == 'vi');
    switch (_status) {
      case WsConnectionStatus.connected:
        color = const Color(0xFF16A34A); // 🟢 Xanh lá
        text = isVi
            ? (isMqtt ? 'Đã kết nối MQTT Cloud' : 'Đã kết nối WebSocket LAN')
            : (isMqtt ? 'MQTT Cloud Connected' : 'WebSocket LAN Connected');
        icon = isMqtt ? Icons.cloud_done_rounded : Icons.lan_rounded;
        break;
      case WsConnectionStatus.connecting:
        color = const Color(0xFFD97706); // 🟡 Cam vàng
        text = isVi
            ? (isMqtt ? 'Đang kiểm tra Cloud...' : 'Đang kiểm tra LAN...')
            : (isMqtt ? 'Connecting Cloud...' : 'Connecting LAN...');
        icon = isMqtt ? Icons.cloud_sync_rounded : Icons.sync_rounded;
        break;
      case WsConnectionStatus.disconnected:
        color = const Color(0xFFE65100);
        text = isVi
            ? (isMqtt ? 'Chờ kết nối Cloud' : 'Chờ kết nối sa bàn LAN')
            : (isMqtt ? 'Ready to Connect (Cloud)' : 'Ready to Connect (LAN)');
        icon = isMqtt ? Icons.cloud_queue_rounded : Icons.lan_outlined;
        break;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
