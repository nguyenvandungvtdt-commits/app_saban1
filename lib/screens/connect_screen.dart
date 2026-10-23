import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
import '../widgets/dynamic_image.dart'; // 🟢 Dùng DynamicImage widget đa nền tảng
import 'master_control_screen.dart';
import '../services/firmware_service.dart';
import 'dart:io'; // 👈 Thêm dòng này vào đầu file
import '../services/config_service.dart';
enum WsConnectionStatus {
  disconnected, // 🔴 Đỏ
  connecting, // 🟡 Vàng
  connected, // 🟢 Xanh
}
class ConnectScreen extends StatefulWidget {
  final String? autoConnectIp;
  const ConnectScreen({super.key, this.autoConnectIp});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}
class _ConnectScreenState extends State<ConnectScreen> {
  String _selectedLang = 'vi';
  final TextEditingController _ipController = TextEditingController(
    text: 'saban-dongvancong.local',
  );
  bool _isLoading = false;
  String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
  String _bgImagePath = 'assets/images/background.png';
  String? localDownloadedBinPath;
  bool _isOTAUploading = false;
  // 🟢 Giữ nguyên khai báo biến (KHÔNG thêm final vì giá trị sẽ thay đổi linh hoạt)
  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  // 🟢 BỔ SUNG CÁC BIẾN MỚI CHO CLOUD & OTA:
  bool _isSyncingCloud = false;
  String _cloudSyncMessage = '';
  // Map<String, dynamic> _cloudProjectInfo = {};
  @override
  void initState() {
    super.initState();
    // 🟢 Tự động kiểm tra ESP32 ngay khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialConnection();
      // 2. Tự động đồng bộ dữ liệu Cloud mới nhất ngầm
    _autoSyncCloudOnLaunch();
    });
    if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
      _ipController.text = widget.autoConnectIp!;
    }
    _loadSavedPreferences();
    _loadSavedLanguage();
    _loadSavedIp();
  }
  Future<void> _autoSyncCloudOnLaunch({bool isManual = false}) async {
  if (_isSyncingCloud) return;

  setState(() {
    _isSyncingCloud = true;
    _cloudSyncMessage = _selectedLang == 'vi'
        ? 'Đang đồng bộ Cloud...'
        : 'Syncing Cloud...';
  });

  if (isManual && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedLang == 'vi'
            ? 'Đang tải cấu hình mới nhất từ Cloud...'
            : 'Fetching latest Cloud config...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  final int timestamp = DateTime.now().millisecondsSinceEpoch;
  final String rawGistUrl =
      'https://gist.githubusercontent.com/nguyenvandungvtdt-commits/b3440aa5a5ab9e6e69bb570b389c88cb/raw/config.json?t=$timestamp';

  try {
    debugPrint('🚀 [CONNECT_CLOUD] Đang tải JSON từ GitHub Gist...');
    final response = await http.get(
      Uri.parse(rawGistUrl),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final String rawJsonStr = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> cloudData = jsonDecode(rawJsonStr);

      // 💾 Lưu cấu hình vào Cache Local theo IP
      await ConfigService.saveConfig(_ipController.text.trim(), rawJsonStr);

      // Cập nhật Tên & Ảnh Sa Bàn lên màn hình Connect
      await _parseCloudHeaderInfo(cloudData);

      if (mounted) {
        setState(() {
          _isSyncingCloud = false;
          _cloudSyncMessage = _selectedLang == 'vi'
              ? 'Đã đồng bộ Cloud mới nhất'
              : 'Cloud Synced';
        });

        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedLang == 'vi'
                  ? 'Cập nhật thành công dữ liệu từ Cloud!'
                  : 'Successfully synced from Cloud!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      throw Exception('HTTP Code ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('⚠️ [CONNECT_CLOUD] Lỗi đồng bộ Cloud (dùng cache local): $e');
    await _loadLocalCachedConfig();
    if (mounted) {
      setState(() {
        _isSyncingCloud = false;
        _cloudSyncMessage = _selectedLang == 'vi'
            ? 'Dùng dữ liệu đã lưu gần nhất'
            : 'Using cached data';
      });
    }
  }
}

// Hàm bổ trợ: Parse Tên dự án & Ảnh overview có kiểm tra ưu tiên Cache
// Future<void> _parseCloudHeaderInfo(Map<String, dynamic> raw) async {
//   final prefs = await SharedPreferences.getInstance();
//   // _cloudProjectInfo = raw['project_info'] ?? {};

//   String? savedProjectName = prefs.getString('saved_project_name');
//   String cloudProjectName = raw['project_info']?['name'] ?? raw['p'] ?? 'SA BÀN THÔNG MINH';

//   String finalName = (savedProjectName != null && savedProjectName.isNotEmpty)
//       ? savedProjectName
//       : cloudProjectName;

//   String cloudOverviewImg = raw['assets']?['overview'] ?? 'assets/images/background.png';
//   String? lastCloudImg = prefs.getString('last_cloud_overview_image');
//   String? savedLocalImage = prefs.getString('saved_overview_image');
//   String finalImg;

//   if (lastCloudImg != null && lastCloudImg != cloudOverviewImg) {
//     await prefs.remove('saved_overview_image');
//     await prefs.setString('last_cloud_overview_image', cloudOverviewImg);
//     finalImg = cloudOverviewImg;
//   } else if (savedLocalImage != null &&
//       savedLocalImage.isNotEmpty &&
//       (kIsWeb || File(savedLocalImage).existsSync())) {
//     finalImg = savedLocalImage;
//   } else {
//     await prefs.setString('last_cloud_overview_image', cloudOverviewImg);
//     finalImg = cloudOverviewImg;
//   }

//   if (mounted) {
//     setState(() {
//       _appTitle = finalName.toUpperCase();
//       _bgImagePath = finalImg;
//     });
//   }
// }
Future<void> _parseCloudHeaderInfo(Map<String, dynamic> raw) async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Tên Dự Án (Ưu tiên tên đã chỉnh sửa riêng ở máy local)
  String? savedProjectName = prefs.getString('saved_connect_title');
  String cloudProjectName =
      raw['project_info']?['name'] ?? raw['p'] ?? 'SA BÀN THÔNG MINH';

  String finalName = (savedProjectName != null && savedProjectName.isNotEmpty)
      ? savedProjectName
      : cloudProjectName;

  // 2. Ảnh Banner Connect Screen (Lấy đúng key 'background' từ Cloud)
  String cloudBackgroundImg =
      raw['assets']?['background'] ?? 'assets/images/background.png';
  String? lastCloudImg = prefs.getString('last_cloud_connect_bg');
  String? savedLocalImage = prefs.getString('saved_connect_bg');
  String finalImg;

  // Tự động cập nhật nếu Cloud có thay đổi ảnh background mới
  if (lastCloudImg != null && lastCloudImg != cloudBackgroundImg) {
    await prefs.remove('saved_connect_bg');
    await prefs.setString('last_cloud_connect_bg', cloudBackgroundImg);
    finalImg = cloudBackgroundImg;
  } else if (savedLocalImage != null &&
      savedLocalImage.isNotEmpty &&
      (kIsWeb || File(savedLocalImage).existsSync())) {
    finalImg = savedLocalImage;
  } else {
    await prefs.setString('last_cloud_connect_bg', cloudBackgroundImg);
    finalImg = cloudBackgroundImg;
  }

  if (mounted) {
    setState(() {
      _appTitle = finalName.toUpperCase();
      _bgImagePath = finalImg;
    });
  }
}

// Hàm đọc Cache local khi không có mạng Internet
// Trong connect_screen.dart:
Future<void> _loadLocalCachedConfig() async {
  try {
    // 🟢 Sửa ConfigService.getConfig thành ConfigService.getSavedJsonConfig()
    final cachedJson = await ConfigService.getSavedJsonConfig();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final Map<String, dynamic> localData = jsonDecode(cachedJson);
      await _parseCloudHeaderInfo(localData);
    }
  } catch (e) {
    debugPrint("Lỗi đọc cache local: $e");
  }
}
  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('saved_ip');
    if (savedIp == null || savedIp == '192.168.0.200') {
      savedIp = 'saban-dongvancong.local';
      await prefs.setString('saved_ip', savedIp); // Đè dữ liệu mới vào máy
    }
    if (mounted) {
      setState(() {
        _ipController.text = savedIp!;
      });
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedTitle = prefs.getString('saved_connect_title');
      String? savedBg = prefs.getString('saved_connect_bg');
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
    } catch (e) {
      debugPrint("Lỗi nạp SharedPreferences ConnectScreen: $e");
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
  String _parseDriveUrl(String url) {
    if (url.trim().isEmpty) return url;
    String trimmed = url.trim();
    String? fileId;
    if (trimmed.contains('drive.google.com')) {
      if (trimmed.contains('/d/')) {
        fileId = trimmed.split('/d/')[1].split('/')[0].split('?')[0];
      } else if (trimmed.contains('id=')) {
        fileId = trimmed.split('id=')[1].split('&')[0];
      }
    }
    if (fileId != null && fileId.isNotEmpty) {
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return trimmed;
  }
  Future<Map<String, dynamic>> _loadRemoteConfigFast() async {
    const String renderUrl = 'https://saban-demo.onrender.com/config';
    try {
      final response = await http
          .get(Uri.parse(renderUrl))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final prefs = await SharedPreferences.getInstance();
        if (!prefs.containsKey('saved_connect_bg')) {
          String? bgUrl = remoteData['assets']?['background'];
          if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
            setState(() {
              _bgImagePath = _parseDriveUrl(bgUrl);
            });
          }
        }
        return remoteData;
      }
    } catch (e) {
      debugPrint('Tải Config từ Render gặp sự cố, thử kênh dự phòng: $e');
    }
    final String gistRawUrl =
        'https://gist.githubusercontent.com/nguyenvandungvtdt-commits/b3440aa5a5ab9e6e69bb570b389c88cb/raw/config.json?t=${DateTime.now().millisecondsSinceEpoch}';
    try {
      final response = await http
          .get(Uri.parse(gistRawUrl))
          .timeout(const Duration(milliseconds: 1800));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final prefs = await SharedPreferences.getInstance();
        if (!prefs.containsKey('saved_connect_bg')) {
          String? bgUrl = remoteData['assets']?['background'];
          if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
            setState(() {
              _bgImagePath = _parseDriveUrl(bgUrl);
            });
          }
        }
        return remoteData;
      }
    } catch (e) {
      debugPrint('Dùng Config nội bộ để tăng tốc: $e');
    }
    try {
      final String localJson = await rootBundle.loadString(
        'assets/config.json',
      );
      return jsonDecode(localJson);
    } catch (e) {
      return {};
    }
  }
  Future<Map<String, String>?> fetchLatestRelease() async {
    final url = Uri.parse(
      'https://api.github.com/repos/nguyenvandungvtdt-commits/saban_firmware/releases/latest',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String tagName = data['tag_name'] ?? '';
        List assets = data['assets'] ?? [];
        var binAsset = assets.firstWhere(
          (asset) => asset['name'].toString().endsWith('.bin'),
          orElse: () => null,
        );
        if (binAsset != null) {
          return {
            'version': tagName,
            'download_url': binAsset['browser_download_url'],
          };
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy thông tin GitHub Release: $e");
    }
    return null;
  }
  Future<void> _downloadFirmwareToPhone() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Đang kiểm tra link Firmware từ Cloud...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      String binUrl = '';
      String? version; // 🟢 Để null mặc định thay vì gán cứng '1.0.2'
      try {
        final configData = await _loadRemoteConfigFast();
        final firmwareInfo = configData['firmware_info'];
        if (firmwareInfo != null && firmwareInfo['bin_url'] != null) {
          binUrl = firmwareInfo['bin_url'].toString().trim();
          if (firmwareInfo['version'] != null) {
            version = firmwareInfo['version'].toString().trim();
          }
        }
      } catch (_) {}
      if (binUrl.isEmpty) {
        final releaseInfo = await fetchLatestRelease();
        if (releaseInfo != null) {
          binUrl = releaseInfo['download_url']!;
          version = releaseInfo['version'];
        }
      }
      if (binUrl.isEmpty) {
        if (mounted) _showErrorSnackBar('Không tìm thấy link Firmware!');
        return;
      }
      if (!mounted) return;
      final displayVersion = version != null
          ? 'v$version'
          : 'Mới nhất (Latest)';
      final String storageNoticeText = Platform.isAndroid
          ? 'File .bin sẽ được tải về lưu trữ tại thư mục Download/bin_esp32 của điện thoại.'
          : 'File .bin sẽ được tải vào mục "Trên iPad của tôi" > Thư mục App > bin_esp32 (Mở ứng dụng Tệp để xem).';
      showDialog(
        context: context,
        builder: (dialogContext) {
          double downloadProgress = 0.0;
          bool isDownloading = false;
          StateSetter? setDialogState;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              setDialogState = setStateDialog;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.download_for_offline_rounded,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Tải Firmware Về Máy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Phiên bản: $displayVersion',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (isDownloading) ...[
                      LinearProgressIndicator(
                        value: downloadProgress,
                        color: const Color(0xFF0284C7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(downloadProgress * 100).toInt()}% - Đang tải file .bin...',
                      ),
                    ] else ...[
                      Text(storageNoticeText),
                    ],
                  ],
                ),
                actions: [
                  if (!isDownloading) ...[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Bắt Đầu Tải'),
                      onPressed: () async {
                        final messengerState = ScaffoldMessenger.of(context);
                        if (setDialogState != null) {
                          setDialogState!(() {
                            isDownloading = true;
                            downloadProgress = 0.1;
                          });
                        }
                        try {
                          final savedPath =
                              await FirmwareService.downloadToBinFolder(
                                binUrl,
                                version: version, // Nếu null, FirmwareService sẽ tự lưu tên 'firmware_latest.bin'
                                onProgress: (received, total) {
                                  if (total != -1 && setDialogState != null) {
                                    setDialogState!(() {
                                      downloadProgress = received / total;
                                    });
                                  }
                                },
                              );
                          if (mounted) {
                            setState(() {
                              localDownloadedBinPath = savedPath;
                            });
                          }
                          if (setDialogState != null) {
                            setDialogState!(() {
                              downloadProgress = 1.0;
                            });
                          }
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          messengerState.showSnackBar(
                            SnackBar(
                              content: Text(
                                Platform.isAndroid
                                    ? 'Đã tải $displayVersion vào thư mục Download/bin_esp32!'
                                    : 'Đã tải $displayVersion vào ứng dụng Tệp (Trên iPad của tôi)!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            _showErrorSnackBar('Tải file thất bại: $e');
                          }
                        }
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) _showErrorSnackBar('Lỗi tải cấu hình: $e');
    }
  }
  Future<void> openWebOTAInChrome(String esp32Ip) async {
    if (!_isValidServerAddress(esp32Ip)) {
      _showErrorSnackBar('Địa chỉ IP không hợp lệ!');
      return;
    }
    final Uri url = Uri.parse('http://$esp32Ip/update');
    try {
      if (mounted) {
        setState(() {
          _isOTAUploading = true;
        });
        debugPrint(
          '[OTA] Đã bật cờ _isOTAUploading = true (Trình duyệt ngoài)',
        );
      }
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && _isOTAUploading) {
            setState(() {
              _isOTAUploading = false;
            });
            debugPrint(
              '[OTA] Tự động reset cờ _isOTAUploading sau 30s timeout',
            );
          }
        });
      } else {
        debugPrint('[OTA] Không thể mở trình duyệt Chrome.');
        if (mounted) {
          setState(() {
            _isOTAUploading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[OTA] Lỗi mở Chrome: $e');
      if (mounted) {
        setState(() {
          _isOTAUploading = false;
        });
      }
    }
  }
  Future<void> _openWebDashboard() async {
    final Uri url = Uri.parse('https://saban-demo.onrender.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('Không thể mở trang web demo!');
    }
  }
  void _connect() async {
    String inputIp = _ipController.text.trim();
    if (inputIp.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
      return;
    }
    bool isCloudDemo =
        inputIp.contains('onrender.com') || inputIp.contains('saban-demo');
    String cleanAddress = inputIp
        .replaceAll('ws://', '')
        .replaceAll('wss://', '')
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/', '');
    if (cleanAddress.contains('.local')) {
      debugPrint(
        '[DEBUG_CONN] ⚠️ Phát hiện mDNS .local, tự động chuyển về IP LAN: 192.168.0.200',
      );
      cleanAddress = '192.168.0.200';
    }
    Uri wsUrl;
    if (isCloudDemo) {
      if (cleanAddress.contains(':')) {
        cleanAddress = cleanAddress.split(':').first;
      }
      wsUrl = Uri.parse('wss://$cleanAddress');
    } else {
      if (cleanAddress.contains(':')) {
        cleanAddress = cleanAddress.split(':').first;
      }
      wsUrl = Uri.parse('ws://$cleanAddress:81');
    }
    if (!_isValidServerAddress(cleanAddress)) {
      _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ip', inputIp);
    setState(() => _isLoading = true);
    WebSocketChannel? channel;
    Map<String, dynamic> configData = {};
    bool isConnected = false;
    StreamSubscription? sub;
    debugPrint(
      '[DEBUG_CONN] ==================================================',
    );
    debugPrint('[DEBUG_CONN] 🚀 BẮT ĐẦU QUÁ TRÌNH KẾT NỐI TỚI: $wsUrl');
    for (int attempt = 1; attempt <= 3; attempt++) {
      debugPrint(
        '[DEBUG_CONN] 🔄 [Lần $attempt/3] Đang thử kết nối WebSocket...',
      );
      Completer<bool> connectionCompleter = Completer<bool>();
      try {
        channel = WebSocketChannel.connect(wsUrl);
        sub = channel.stream.listen(
          (data) {
            debugPrint(
              '[DEBUG_CONN] 📥 Nhận tín hiệu bắt tay từ Sa bàn: $data',
            );
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete(true);
            }
          },
          onError: (err) {
            debugPrint('[DEBUG_CONN] ❌ Lỗi Stream khi bắt tay: $err');
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete(false);
            }
          },
          onDone: () {
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete(false);
            }
          },
        );
        await Future.delayed(const Duration(milliseconds: 300));
        channel.sink.add('SYNC_ALL');
        int timeoutMs = isCloudDemo ? 5000 : 3000;
        isConnected = await connectionCompleter.future.timeout(
          Duration(milliseconds: timeoutMs),
          onTimeout: () {
            debugPrint(
              '[DEBUG_CONN] ⚠️ [Lần $attempt/3] Hết thời gian chờ phản hồi!',
            );
            return false;
          },
        );
        if (isConnected) {
          debugPrint('[DEBUG_CONN] 🎉 [Lần $attempt/3] KẾT NỐI THÀNH CÔNG!');
          break;
        }
      } catch (e) {
        debugPrint('[DEBUG_CONN] ❌ [Lần $attempt/3] Ngoại lệ: $e');
        await sub?.cancel();
        sub = null;
        try {
          await channel?.sink.close();
        } catch (_) {}
        channel = null;
      }
      if (!isConnected && attempt < 3) {
        await sub?.cancel();
        sub = null;
        debugPrint('[DEBUG_CONN] ⏳ Đang chờ 500ms trước khi thử lại...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (isConnected && channel != null) {
      await sub?.cancel();
      sub = null;
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('[DEBUG_CONN] 📥 Bắt đầu tải Remote Config...');
      try {
        configData = await _loadRemoteConfigFast().timeout(
          const Duration(seconds: 3),
          onTimeout: () => <String, dynamic>{},
        );
      } catch (_) {
        configData = {};
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MasterControlScreen(
            currentLang: _selectedLang,
            channel: channel!, // Lúc này channel đã sạch subscription, có thể listen thoải mái
            ip: cleanAddress,
            configData: configData,
            ledStates: const {},
          ),
        ),
      );
    } else {
      await sub?.cancel();
      sub = null;
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(
        'Không thể kết nối tới sa bàn ($cleanAddress). Vui lòng thử lại!',
      );
    }
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
    final TextEditingController urlController = TextEditingController(
      text: _bgImagePath.startsWith('http') ? _bgImagePath : '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF0369A1)),
              SizedBox(width: 10),
              Text(
                'Cập Nhật Màn Hình Chờ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu Đề Ứng Dụng',
                    prefixIcon: Icon(Icons.title_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Link Ảnh Google Drive / Direct URL',
                    hintText: 'Dán link Google Drive/Web...',
                    prefixIcon: Icon(Icons.link_rounded),
                    border: OutlineInputBorder(),
                  ),
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
                        if (mounted) {
                          setState(() {
                            _bgImagePath = cleanPath;
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('saved_connect_bg', cleanPath);
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        debugPrint("❌ Lỗi chọn ảnh banner: $e");
                      }
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('saved_connect_title');
                        await prefs.remove('saved_connect_bg');
                        if (mounted) {
                          setState(() {
                            _bgImagePath = 'assets/images/background.png';
                          });
                        }
                        _loadRemoteConfigFast();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã khôi phục tiêu đề & ảnh gốc từ Cloud!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint("❌ Lỗi khôi phục banner: $e");
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Khôi phục gốc từ Cloud',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                String newTitle = titleController.text.trim();
                String newUrl = urlController.text.trim();
                final prefs = await SharedPreferences.getInstance();
                if (mounted) {
                  setState(() {
                    if (newTitle.isNotEmpty) {
                      _appTitle = newTitle;
                    }
                    if (newUrl.isNotEmpty) {
                      _bgImagePath = _parseDriveUrl(newUrl);
                    }
                  });
                  if (newTitle.isNotEmpty) {
                    await prefs.setString('saved_connect_title', newTitle);
                  }
                  if (newUrl.isNotEmpty) {
                    await prefs.setString(
                      'saved_connect_bg',
                      _parseDriveUrl(newUrl),
                    );
                  }
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Áp Dụng'),
            ),
          ],
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
                    // child: Column(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         const Icon(
                    //           Icons.tune_rounded,
                    //           color: Color(0xFF0369A1),
                    //           size: 20,
                    //         ),
                    //         const SizedBox(width: 8),
                    //         Flexible(
                    //           child: Text(
                    //             _appTitle,
                    //             textAlign: TextAlign.center,
                    //             style: const TextStyle(
                    //               fontSize: 14,
                    //               fontWeight: FontWeight.bold,
                    //               color: Color(0xFF0369A1),
                    //               letterSpacing: 0.8,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //     const SizedBox(height: 14),
                    //     TextField(
                    //       controller: _ipController,
                    //       keyboardType: TextInputType.url,
                    //       style: const TextStyle(
                    //         fontSize: 15,
                    //         fontWeight: FontWeight.bold,
                    //         color: Color(0xFF0F172A),
                    //       ),
                    //       decoration: InputDecoration(
                    //         labelText: _selectedLang == 'vi'
                    //             ? 'Địa chỉ IP / Server Sa bàn'
                    //             : 'IP Address / Model Server',
                    //         labelStyle: const TextStyle(
                    //           color: Color(0xFF0369A1),
                    //           fontSize: 13,
                    //         ),
                    //         hintText: _selectedLang == 'vi'
                    //             ? 'Ví dụ: saban-dongvancong.local hoặc saban-demo.onrender.com'
                    //             : 'e.g., saban-dongvancong.local or saban-demo.onrender.com',
                    //         prefixIcon: const Icon(
                    //           Icons.wifi_rounded,
                    //           color: Color(0xFF0284C7),
                    //           size: 20,
                    //         ),
                    //         contentPadding: const EdgeInsets.symmetric(
                    //           vertical: 12,
                    //           horizontal: 16,
                    //         ),
                    //         filled: true,
                    //         fillColor: const Color(0xFFF0F9FF),
                    //         enabledBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //           borderSide: const BorderSide(
                    //             color: Color(0xFFBAE6FD),
                    //             width: 1.2,
                    //           ),
                    //         ),
                    //         focusedBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //           borderSide: const BorderSide(
                    //             color: Color(0xFF0284C7),
                    //             width: 2,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(height: 14),
                    //     SizedBox(
                    //       width: double.infinity,
                    //       height: 48,
                    //       child: InkWell(
                    //         onTap: _isLoading ? null : _connect,
                    //         borderRadius: BorderRadius.circular(12),
                    //         child: AnimatedContainer(
                    //           duration: const Duration(milliseconds: 200),
                    //           decoration: BoxDecoration(
                    //             gradient: _isLoading
                    //                 ? const LinearGradient(
                    //                     colors: [
                    //                       Color(0xFF94A3B8),
                    //                       Color(0xFF64748B),
                    //                     ],
                    //                   )
                    //                 : const LinearGradient(
                    //                     colors: [
                    //                       Color(0xFF0284C7),
                    //                       Color(0xFF0369A1),
                    //                     ],
                    //                     begin: Alignment.topLeft,
                    //                     end: Alignment.bottomRight,
                    //                   ),
                    //             borderRadius: BorderRadius.circular(12),
                    //             boxShadow: [
                    //               BoxShadow(
                    //                 color: const Color(0xFF0284C7)
                    //                     .withValues(alpha: 0.3),
                    //                 blurRadius: 12,
                    //                 offset: const Offset(0, 4),
                    //               ),
                    //             ],
                    //           ),
                    //           child: Center(
                    //             child: _isLoading
                    //                 ? Row(
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.center,
                    //                     children: [
                    //                       const SizedBox(
                    //                         width: 18,
                    //                         height: 18,
                    //                         child: CircularProgressIndicator(
                    //                           color: Colors.white,
                    //                           strokeWidth: 2,
                    //                         ),
                    //                       ),
                    //                       const SizedBox(width: 10),
                    //                       Text(
                    //                         _selectedLang == 'vi'
                    //                             ? 'Đang kết nối, vui lòng chờ chút ạ!'
                    //                             : 'Connecting, please wait...',
                    //                         style: const TextStyle(
                    //                           color: Colors.white,
                    //                           fontWeight: FontWeight.bold,
                    //                           fontSize: 14,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   )
                    //                 : Row(
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.center,
                    //                     children: [
                    //                       const Icon(
                    //                         Icons.power_settings_new_rounded,
                    //                         color: Colors.white,
                    //                         size: 18,
                    //                       ),
                    //                       const SizedBox(width: 8),
                    //                       Text(
                    //                         _selectedLang == 'vi'
                    //                             ? 'KẾT NỐI VÀ TẢI SA BÀN'
                    //                             : 'CONNECT & LOAD SCALE MODEL',
                    //                         style: const TextStyle(
                    //                           color: Colors.white,
                    //                           fontSize: 14,
                    //                           fontWeight: FontWeight.bold,
                    //                           letterSpacing: 0.8,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1️⃣ Dòng Tiêu đề Màn hình
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
                        // 🟢 2. CẠC BADGE THÔNG MINH HIỂN THỊ TRẠNG THÁI KẾT NỐI (ĐỎ/VÀNG/XANH)
                        // _buildConnectionBadge(),
                        // 🟢 2. CẠC BADGE THÔNG MINH HIỂN THỊ TRẠNG THÁI KẾT NỐI (ESP32 + CLOUD)
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildConnectionBadge(),  // Badge kết nối phần cứng ESP32
      const SizedBox(width: 8),
      _buildCloudSyncBadge(),   // 🟢 Badge trạng thái đồng bộ dữ liệu Cloud
    ],
  ),
  const SizedBox(height: 14),
                        // const SizedBox(height: 14),
                        // 3️⃣ Ô Nhập Địa chỉ IP / Server
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
                                ? 'Ví dụ: saban-dongvancong.local hoặc 192.168.0.200'
                                : 'e.g., saban-dongvancong.local or 192.168.0.200',
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
                        // 4️⃣ Nút Bấm Kết Nối & Tải Sa Bàn
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
              onSelected: (value) {
                if (value == 'sync_cloud') {
    // 🟢 Gọi hàm đồng bộ Cloud thủ công khi người dùng chọn menu
    _autoSyncCloudOnLaunch(isManual: true);
  }
               else if (value == 'demo_mode') {
                  setState(() {
                    _ipController.text = 'saban-demo.onrender.com';
                  });
                  _connect();
                } else if (value == 'real_mode') {
                  setState(() {
                    _ipController.text = 'saban-dongvancong.local';
                  });
                  _connect();
                } else if (value == 'web_demo') {
                  _openWebDashboard();
                } else if (value == 'edit_image') {
                  _showImageEditDialog(context);
                } else if (value == 'download_firmware') {
                  _downloadFirmwareToPhone();
                } else if (value == 'open_chrome_ota') {
                  openWebOTAInChrome(_ipController.text.trim());
                }
              },
              itemBuilder: (BuildContext context) => [
                // 🟢 BỔ SUNG MỤC ĐỒNG BỘ CLOUD VÀO ĐÂY
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
  const PopupMenuDivider(), // Đường gạch ngang phân cách
                PopupMenuItem(
                  value: 'demo_mode',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Dùng Sa Bàn Demo Cloud'
                              : 'Use Cloud Demo Model',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'real_mode',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lan_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Dùng Sa Bàn Thực (Mạng LAN)'
                              : 'Use Real Model (LAN)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'web_demo',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_browser_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? 'Mở Dashboard Web Demo'
                              : 'Open Web Demo Dashboard',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
                              ? 'Chỉnh Sửa Tiêu Đề / Ảnh Banner'
                              : 'Edit Title / Banner Image',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'download_firmware',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.download_for_offline_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLang == 'vi'
                              ? '1. Tải Firmware .bin về điện thoại'
                              : '1. Download Firmware .bin to Phone',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  setState(() {
                    _selectedLang = newLang;
                    _appTitle = _selectedLang == 'vi'
                        ? 'ĐIỀU KHIỂN SA BÀN THÔNG MINH'
                        : 'SMART SCALE MODEL CONTROLLER';
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', newLang);
                  debugPrint("🌐 Switched Language to: $_selectedLang");
                },
                child: Container(
                  width: 96, // 🟢 Độ rộng thoải mái cho chữ và cờ
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE), // Nền xanh nhạt
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
                              Text(
                                'VN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                              Text(
                                'EN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0369A1),
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
                          width: 44, // 🟢 Chiều rộng khối nổi
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
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
                              const SizedBox(width: 2),
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
  // 🟢 Hàm ngầm kiểm tra kết nối khi mở App
  // 🟢 1. Hàm kiểm tra ngầm khi mở màn hình (Chỉ thử kết nối nhẹ ngầm)
Future<void> _checkInitialConnection() async {
  if (_isLoading || _status == WsConnectionStatus.connecting) return;
  if (mounted) {
    setState(() {
      _status = WsConnectionStatus.connecting; // 🟡 Chuyển Vàng: Đang dò ESP32
    });
  }
  String rawInput = _ipController.text.trim();
  if (rawInput.isEmpty) rawInput = 'saban-dongvancong.local';
  // Lọc sạch prefix http/ws nếu người dùng lỡ nhập
  final cleanHost = rawInput.replaceAll(RegExp(r'https?://|ws://'), '').replaceAll('/', '');
  // Danh sách địa chỉ cần dò: Ưu tiên Host nhập vào trước, sau đó tới IP tĩnh dự phòng
  final List<String> hostsToTry = [cleanHost];
  if (cleanHost != '192.168.0.200') {
    hostsToTry.add('192.168.0.200'); // Backup IP tĩnh nếu mDNS thất bại
  }
  bool connected = false;
  for (String host in hostsToTry) {
    if (connected) break;
    try {
      debugPrint('🔍 [STATUS_CHECK] Thử kết nối tới: ws://$host:81');
      final uri = Uri.parse('ws://$host:81');
      final channel = WebSocketChannel.connect(uri);
      // Đặt timeout 2 giây cho mỗi phương án dò
      await channel.ready.timeout(const Duration(seconds: 2));
      // Lắng nghe tín hiệu phản hồi
      final stream = channel.stream.asBroadcastStream();
      final sub = stream.listen((message) {
        if (!connected && mounted) {
          connected = true;
          debugPrint('🟢 [STATUS_CHECK] Thành công kết nối qua: $host -> CHUYỂN XANH!');
          setState(() {
            _status = WsConnectionStatus.connected; // 🟢 Báo Xanh ngay!
          });
        }
        channel.sink.close();
      });
      // Cho phép ngắt kết nối kiểm tra sau khi xác nhận
      await Future.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
    } catch (e) {
      debugPrint('⚠️ [STATUS_CHECK] Không kết nối được tới $host: $e');
      // Tự động chuyển sang host tiếp theo trong danh sách hostsToTry
    }
  }
  // Nếu đã thử tất cả địa chỉ mà vẫn thất bại
  if (!connected && mounted) {
    debugPrint('🔴 [STATUS_CHECK] Thất bại toàn bộ phương án kết nối -> Báo Đỏ.');
    setState(() {
      _status = WsConnectionStatus.disconnected; // 🔴 Chuyển Đỏ
    });
  }
}
  Widget _buildConnectionBadge() {
    Color color;
    String text;
    IconData icon;
    // 🟢 Bỏ nhánh 'default:' vì Switch đã bao phủ 100% các giá trị của Enum
    switch (_status) {
      case WsConnectionStatus.connected:
        color = const Color(0xFF16A34A); // Xanh lá
        text = _selectedLang == 'vi'
            ? 'Đã kết nối ESP32 Sẵn sàng'
            : 'Connected & Ready';
        icon = Icons.check_circle_rounded;
        break;
      case WsConnectionStatus.connecting:
        color = const Color(0xFFD97706); // Cam / Vàng
        text = _selectedLang == 'vi'
            ? 'Đang kiểm tra kết nối...'
            : 'Connecting...';
        icon = Icons.sync_rounded;
        break;
      case WsConnectionStatus.disconnected:
        color = const Color(0xFFDC2626); // Đỏ
        text = _selectedLang == 'vi' ? 'Chưa kết nối sa bàn' : 'Disconnected';
        icon = Icons.cancel_rounded;
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
