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
import '../screens/web_ota_screen.dart'; // 🟢 Import màn hình WebOTAScreen
import '../widgets/dynamic_image.dart'; // 🟢 Dùng DynamicImage widget đa nền tảng
import 'master_control_screen.dart';
import '../services/firmware_service.dart';
import 'dart:io'; // 👈 Thêm dòng này vào đầu file
import 'package:web_socket_channel/io.dart';
class ConnectScreen extends StatefulWidget {
  final String? autoConnectIp;
  const ConnectScreen({super.key, this.autoConnectIp});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}
class _ConnectScreenState extends State<ConnectScreen> {
String _selectedLang = 'vi';
final TextEditingController _ipController =
    TextEditingController(text: 'saban-dongvancong.local');   
bool _isLoading = false;
String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
String _bgImagePath = 'assets/images/background.png';
  String? localDownloadedBinPath;
  bool _isOTAUploading = false;
  IOWebSocketChannel? _channel;
  @override
  void initState() {
    super.initState();
    if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
      _ipController.text = widget.autoConnectIp!;
    }
    _loadSavedPreferences();
    _loadSavedLanguage();
    _loadSavedIp();
  }
Future<void> _loadSavedIp() async {
  final prefs = await SharedPreferences.getInstance();
  String? savedIp = prefs.getString('saved_ip');

  // 🟢 Nếu chưa lưu IP HOẶC dữ liệu trong máy đang dính IP cũ '192.168.0.27'
  // thì ép buộc cập nhật sang tên miền mDNS mới
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
        final Map<String, dynamic> remoteData =
            jsonDecode(utf8.decode(response.bodyBytes));
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
        final Map<String, dynamic> remoteData =
            jsonDecode(utf8.decode(response.bodyBytes));
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
      final String localJson =
          await rootBundle.loadString('assets/config.json');
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
// Future<void> _downloadFirmwareToPhone() async {
//   if (!mounted) return;
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Row(
//         children: [
//           SizedBox(
//             width: 18,
//             height: 18,
//             child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//           ),
//           SizedBox(width: 12),
//           Text('Đang kiểm tra link Firmware từ Cloud...'),
//         ],
//       ),
//       duration: Duration(seconds: 2),
//     ),
//   );
//   try {
//     String binUrl = '';
//     String? version; // 🟢 Để null mặc định thay vì gán cứng '1.0.2'
//     try {
//       final configData = await _loadRemoteConfigFast();
//       final firmwareInfo = configData['firmware_info'];
//       if (firmwareInfo != null && firmwareInfo['bin_url'] != null) {
//         binUrl = firmwareInfo['bin_url'].toString().trim();
//         if (firmwareInfo['version'] != null) {
//           version = firmwareInfo['version'].toString().trim();
//         }
//       }
//     } catch (_) {}
//     if (binUrl.isEmpty) {
//       final releaseInfo = await fetchLatestRelease();
//       if (releaseInfo != null) {
//         binUrl = releaseInfo['download_url']!;
//         version = releaseInfo['version'];
//       }
//     }
//     if (binUrl.isEmpty) {
//       if (mounted) _showErrorSnackBar('Không tìm thấy link Firmware!');
//       return;
//     }
//     if (!mounted) return;
//     final displayVersion = version != null ? 'v$version' : 'Mới nhất (Latest)';
//     final String storageNoticeText = Platform.isAndroid
//         ? 'File .bin sẽ được tải về lưu trữ tại thư mục Download/bin_esp32 của điện thoại.'
//         : 'File .bin sẽ được tải vào mục "Trên iPad của tôi" > Thư mục App > bin_esp32 (Mở ứng dụng Tệp để xem).';
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         double downloadProgress = 0.0;
//         bool isDownloading = false;
//         StateSetter? setDialogState;
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             setDialogState = setStateDialog;
//             return AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               title: const Row(
//                 children: [
//                   Icon(Icons.download_for_offline_rounded, color: Color(0xFF0284C7)),
//                   SizedBox(width: 10),
//                   Text('Tải Firmware Về Máy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('• Phiên bản: $displayVersion', style: const TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   if (isDownloading) ...[
//                     LinearProgressIndicator(value: downloadProgress, color: const Color(0xFF0284C7)),
//                     const SizedBox(height: 8),
//                     Text('${(downloadProgress * 100).toInt()}% - Đang tải file .bin...'),
//                   ] else ...[
//                     Text(storageNoticeText),
//                   ],
//                 ],
//               ),
//               actions: [
//                 if (!isDownloading) ...[
//                   TextButton(
//                     onPressed: () => Navigator.pop(dialogContext),
//                     child: const Text('Hủy'),
//                   ),
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0284C7),
//                       foregroundColor: Colors.white,
//                     ),
//                     icon: const Icon(Icons.download_rounded, size: 18),
//                     label: const Text('Bắt Đầu Tải'),
//                     onPressed: () async {
//                       final messengerState = ScaffoldMessenger.of(context);
//                       if (setDialogState != null) {
//                         setDialogState!(() {
//                           isDownloading = true;
//                           downloadProgress = 0.1;
//                         });
//                       }
//                       try {
//                         final savedPath = await FirmwareService.downloadToBinFolder(
//                           binUrl,
//                           version: version, // Nếu null, FirmwareService sẽ tự lưu tên 'firmware_latest.bin'
//                           onProgress: (received, total) {
//                             if (total != -1 && setDialogState != null) {
//                               setDialogState!(() {
//                                 downloadProgress = received / total;
//                               });
//                             }
//                           },
//                         );
//                         if (mounted) {
//                           setState(() {
//                             localDownloadedBinPath = savedPath;
//                           });
//                         }
//                         if (setDialogState != null) {
//                           setDialogState!(() {
//                             downloadProgress = 1.0;
//                           });
//                         }
//                         await Future.delayed(const Duration(milliseconds: 500));
//                         if (dialogContext.mounted) {
//                           Navigator.pop(dialogContext);
//                         }
//                         messengerState.showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               Platform.isAndroid
//                                   ? 'Đã tải $displayVersion vào thư mục Download/bin_esp32!'
//                                   : 'Đã tải $displayVersion vào ứng dụng Tệp (Trên iPad của tôi)!',
//                             ),
//                             backgroundColor: Colors.green,
//                           ),
//                         );
//                       } catch (e) {
//                         if (dialogContext.mounted) {
//                           Navigator.pop(dialogContext);
//                         }
//                         if (mounted) {
//                           _showErrorSnackBar('Tải file thất bại: $e');
//                         }
//                       }
//                     },
//                   ),
//                 ],
//               ],
//             );
//           },
//         );
//       },
//     );
//   } catch (e) {
//     if (mounted) _showErrorSnackBar('Lỗi tải cấu hình: $e');
//   }
// }

Future<void> _downloadFirmwareToPhone() async {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

    // 1. Thử lấy thông tin từ Remote Config
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

    // 2. Nếu không có, thử lấy từ GitHub Release / API cập nhật
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

    // Chuỗi hiển thị phiên bản trên UI dialog
    final displayVersion = version != null ? 'v$version' : 'Mới nhất (Latest)';

    // Chuẩn bị văn bản thông báo theo hệ điều hành
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.download_for_offline_rounded, color: Color(0xFF0284C7)),
                  SizedBox(width: 10),
                  Text('Tải Firmware Về Máy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Phiên bản: $displayVersion', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isDownloading) ...[
                    LinearProgressIndicator(value: downloadProgress, color: const Color(0xFF0284C7)),
                    const SizedBox(height: 8),
                    Text('${(downloadProgress * 100).toInt()}% - Đang tải file .bin...'),
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
                        // 🟢 Tải file .bin thông qua FirmwareService
                        final savedPath = await FirmwareService.downloadToBinFolder(
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
                        await Future.delayed(const Duration(milliseconds: 500));
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
  // Future<void> _uploadLocalBinToESP32() async {
  //   final ip = _ipController.text.trim();
  //   if (!_isValidServerAddress(ip)) {
  //     _showErrorSnackBar(
  //       _selectedLang == 'vi'
  //           ? 'Vui lòng nhập địa chỉ IP/Server hợp lệ!'
  //           : 'Please enter a valid IP address or Server URL!',
  //     );
  //     return;
  //   }
  //   String? binPath = FirmwareService.localDownloadedBinPath;
  //   if (binPath == null || !await File(binPath).exists()) {
  //     final latestFile = await FirmwareService.getLatestDownloadedBinFile();
  //     if (latestFile != null) {
  //       binPath = latestFile.path;
  //       FirmwareService.localDownloadedBinPath = binPath;
  //     }
  //   }
  //   if (!mounted) return;
  //   if (binPath == null || !await File(binPath).exists()) {
  //     _showErrorSnackBar(
  //       _selectedLang == 'vi'
  //           ? 'Không tìm thấy file Firmware (.bin) nào! Vui lòng tải Firmware trước.'
  //           : 'No Firmware (.bin) file found! Please download the Firmware first.',
  //     );
  //     return;
  //   }
  //   setState(() {
  //     _isOTAUploading = true;
  //   });
  //   if (!mounted) return;
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => WebOTAScreen(
  //         ip: ip,
  //         binFilePath: binPath, // Truyền file .bin đã trỏ chính xác
  //       ),
  //     ),
  //   );
  //   if (!mounted) return;
  //   setState(() {
  //     _isOTAUploading = false;
  //   });
  //   _connect();
  // }
Future<void> _uploadLocalBinToESP32() async {
  // 1. Thử lấy đường dẫn từ biến lưu tạm
  String? binPath = FirmwareService.localDownloadedBinPath;
  File? binFile;

  // 2. Kiểm tra nếu biến tạm có giá trị và file thực sự tồn tại
  if (binPath != null && binPath.isNotEmpty) {
    binFile = File(binPath);
    if (!await binFile.exists()) {
      binFile = null; // Reset nếu đường dẫn cũ không còn hợp lệ
    }
  }

  // 3. Nếu chưa tìm thấy, quét trực tiếp thư mục Download/bin_esp32
  if (binFile == null) {
    binFile = await FirmwareService.getLatestDownloadedBinFile();
    if (binFile != null) {
      binPath = binFile.path;
      FirmwareService.localDownloadedBinPath = binPath; // Cập nhật lại cache
    }
  }

  // 🟢 Điểm kiểm tra an toàn 1 (Trước khi cập nhật UI)
  if (!mounted) return;

  // 4. Kiểm tra lần cuối cùng xem binFile đã thực sự hợp lệ chưa
  if (binFile == null || !await binFile.exists() || (await binFile.length()) == 0) {
    _showErrorSnackBar('Không tìm thấy file Firmware (.bin) nào! Vui lòng tải Firmware trước.');
    return;
  }

  debugPrint('[OTA] Đã tìm thấy file sẵn sàng nạp: ${binFile.path} (${await binFile.length()} bytes)');

  setState(() {
    _isOTAUploading = true;
  });

  // 🟢 Điểm kiểm tra an toàn 2 (Trước khi chuyển màn hình)
  if (!mounted) return;

  // Lấy IP kết nối hiện tại (Ưu tiên IP tĩnh của widget hoặc IP người dùng vừa nhập trong controller)
  final String currentIp = widget.autoConnectIp ?? _ipController.text.trim();

  // 5. Chuyển sang WebOTAScreen truyền thêm kênh WebSocket active
  final bool? otaSuccess = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => WebOTAScreen(
        ip: currentIp,
        binFilePath: binFile?.path,
        webSocketChannel: _channel, // 🟢 Truyền kênh WebSocket đang kết nối
      ),
    ),
  );

  // 🟢 Điểm kiểm tra an toàn 3 (Sau khi từ WebOTAScreen quay về)
  if (!mounted) return;

  setState(() {
    _isOTAUploading = false;
  });

  // 6. Nếu vừa nạp OTA thành công: Dọn dẹp kết nối cũ và tự động tái kết nối sau 3 giây
  if (otaSuccess == true) {
    debugPrint('[OTA] Nạp thành công! Đang làm sạch kết nối và chờ ESP32 khởi động lại...');
_disconnectSocket();
    // Đóng WebSocket cũ an toàn (Tránh đụng độ socket khi ESP32 đổi session)
    try {
      _channel?.sink.close();
      _channel = null;
    } catch (e) {
      debugPrint('[OTA] Lỗi đóng WebSocket cũ: $e');
    }

    // Chờ 3 giây để ESP32 chạy xong tiến trình reboot và bắt lại IP tĩnh 192.168.0.200
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _connect(); // Tự động kết nối lại vào sa bàn
    }
  }
}
// 🟢 HÀM NGẮT KẾT NỐI SOCKET AN TOÀN KHI DỌN BỘ NHỚ HOẶC NẠP OTA XONG
 void _disconnectSocket() {
    try {
      _channel?.sink.close();
      _channel = null;
      debugPrint('[WS] Đã đóng kết nối WebSocket cũ.');
    } catch (e) {
      debugPrint('[WS] Lỗi khi đóng WebSocket: $e');
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
        debugPrint('[OTA] Đã bật cờ _isOTAUploading = true (Trình duyệt ngoài)');
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
            debugPrint('[OTA] Tự động reset cờ _isOTAUploading sau 30s timeout');
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
  // void _connect() async {
  //   final ip = _ipController.text.trim();
  //   if (ip.isEmpty) {
  //     _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
  //     return;
  //   }
  //   if (!_isValidServerAddress(ip)) {
  //     _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
  //     return;
  //   }
  //   // 🟢 BỔ SUNG: Lưu địa chỉ IP / Tên miền hiện tại vào SharedPreferences
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('saved_ip', ip);
  //   setState(() => _isLoading = true);
  //   try {
  //     Uri wsUrl;
  //     if (ip.contains('onrender.com') || ip.startsWith('wss://') || ip.startsWith('ws://')) {
  //       String formatted = ip;
  //       if (!formatted.startsWith('ws://') && !formatted.startsWith('wss://')) {
  //         formatted = 'wss://$formatted';
  //       }
  //       wsUrl = Uri.parse(formatted);
  //     } else {
  //       wsUrl = Uri.parse('ws://$ip:81');
  //     }
  //     final channel = WebSocketChannel.connect(wsUrl);
  //     final results = await Future.wait([
  //       channel.ready.timeout(
  //         const Duration(seconds: 4),
  //         onTimeout: () => throw TimeoutException('Mất kết nối'),
  //       ),
  //       _loadRemoteConfigFast(),
  //     ]);
  //     final configData = results[1] as Map<String, dynamic>;
  //     if (!mounted) return;
  //     setState(() => _isLoading = false);
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => MasterControlScreen(
  //           currentLang: _selectedLang, // 👈 Truyền giá trị ngôn ngữ sang màn hình điều khiển
  //           channel: channel,
  //           ip: ip,
  //           configData: configData,
  //           ledStates: const {},
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() => _isLoading = false);
  //     _showErrorSnackBar(
  //         'Không thể kết nối tới sa bàn ($ip). Vui lòng kiểm tra lại IP hoặc Wi-Fi!');
  //   }
  // }
//  void _connect() async {
//     String ip = _ipController.text.trim();
//     if (ip.isEmpty) {
//       _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
//       return;
//     }

//     // 🟢 1. CHUẨN HÓA IP: Xóa ws://, http://, port thừa và đổi .local sang IP tĩnh
//     ip = ip.replaceAll('ws://', '').replaceAll('wss://', '').replaceAll('http://', '');
//     if (ip.contains('.local')) {
//       debugPrint('[DEBUG_CONN] ⚠️ Phát hiện tên miền .local, tự động chuyển về IP: 192.168.0.200');
//       ip = '192.168.0.200';
//     }
//     if (ip.contains(':')) {
//       ip = ip.split(':').first; // Lấy thuần túy IP (vd: 192.168.0.200)
//     }

//     if (!_isValidServerAddress(ip)) {
//       _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
//       return;
//     }

//     // 🟢 2. Lưu IP đã chuẩn hóa vào SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('saved_ip', ip);

//     setState(() => _isLoading = true);

//     WebSocketChannel? channel;
//     Map<String, dynamic> configData = {};
//     bool isConnected = false;

//     // Định dạng URI chuẩn cổng :81 cho ESP32
//     final Uri wsUrl = Uri.parse('ws://$ip:81');

//     debugPrint('[DEBUG_CONN] ==================================================');
//     debugPrint('[DEBUG_CONN] 🚀 BẮT ĐẦU QUÁ TRÌNH KẾT NỐI TỚI: $wsUrl');

//     // 🟢 3. VÒNG LẶP RETRY 3 LẦN NẾU ESP32 ĐANG BẬN NHẢ SLOT SOCKET
//     for (int attempt = 1; attempt <= 3; attempt++) {
//       debugPrint('[DEBUG_CONN] 🔄 [Lần $attempt/3] Đang gửi yêu cầu Handshake...');
//       final Stopwatch sw = Stopwatch()..start();

//       try {
//         // Đóng socket cũ nếu đang treo ở client
//         try {
//           await channel?.sink.close();
//         } catch (_) {}

//         channel = WebSocketChannel.connect(wsUrl);

//         // Đợi phản hồi Handshake (Timeout 3.5s cho mỗi lần thử)
//         await channel.ready.timeout(
//           const Duration(milliseconds: 3500),
//           onTimeout: () {
//             debugPrint('[DEBUG_CONN] ⚠️ [Lần $attempt/3] Timeout sau 3.5s! ESP32 chưa nhả socket.');
//             throw TimeoutException('WebSocket Ready Timeout');
//           },
//         );

//         sw.stop();
//         debugPrint('[DEBUG_CONN] 🎉 [Lần $attempt/3] KẾT NỐI VỚI ESP32 THÀNH CÔNG sau ${sw.elapsedMilliseconds}ms!');
//         isConnected = true;
//         break; // Kết nối thành công -> Bỏ qua các lần retry còn lại

//       } catch (e) {
//         sw.stop();
//         debugPrint('[DEBUG_CONN] ❌ [Lần $attempt/3] Thất bại (${sw.elapsedMilliseconds}ms). Chi tiết: $e');

//         try {
//           await channel?.sink.close();
//           channel = null;
//         } catch (_) {}

//         if (attempt < 3) {
//           debugPrint('[DEBUG_CONN] ⏳ Đang chờ 600ms để ESP32 giải phóng RAM/Socket rồi thử lại...');
//           await Future.delayed(const Duration(milliseconds: 600));
//         }
//       }
//     }

//     // 🟢 4. XỬ LÝ KẾT QUẢ KẾT NỐI
//     if (isConnected && channel != null) {
//       // Tải Remote Config độc lập (Timeout 3 giây)
//       debugPrint('[DEBUG_CONN] 📥 Bắt đầu tải Remote Config...');
//       try {
//         configData = await _loadRemoteConfigFast().timeout(
//           const Duration(seconds: 3),
//           onTimeout: () {
//             debugPrint('[DEBUG_CONN] ⚠️ Tải Config bị Timeout, dùng Config mặc định.');
//             return <String, dynamic>{};
//           },
//         );
//         debugPrint('[DEBUG_CONN] ✅ Tải Remote Config hoàn tất.');
//       } catch (configErr) {
//         debugPrint('[DEBUG_CONN] ⚠️ Lỗi tải Config ($configErr), vẫn tiếp tục vào sa bàn.');
//         configData = {};
//       }

//       if (!mounted) return;
//       setState(() => _isLoading = false);

//       // Chuyển sang màn hình Điều khiển
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MasterControlScreen(
//             currentLang: _selectedLang,
//             channel: channel!,
//             ip: ip,
//             configData: configData,
//             ledStates: const {},
//           ),
//         ),
//       );

//     } else {
//       debugPrint('[DEBUG_CONN] ❌ RẤT TIẾC: Thử cả 3 lần đều không thể kết nối tới ESP32!');
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showErrorSnackBar(
//         'Không thể kết nối tới sa bàn ($ip). Vui lòng thử lại!',
//       );
//     }
//   }
void _connect() async {
  String ip = _ipController.text.trim();
  if (ip.isEmpty) {
    _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
    return;
  }
  ip = ip.replaceAll('ws://', '').replaceAll('wss://', '').replaceAll('http://', '');
  if (ip.contains('.local')) {
    debugPrint('[DEBUG_CONN] ⚠️ Phát hiện tên miền .local, tự động chuyển về IP: 192.168.0.200');
    ip = '192.168.0.200';
  }
  if (ip.contains(':')) {
    ip = ip.split(':').first;
  }
  if (!_isValidServerAddress(ip)) {
    _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('saved_ip', ip);

  setState(() => _isLoading = true);

  WebSocketChannel? channel;
  Map<String, dynamic> configData = {};
  bool isConnected = false;
  
  // 🟢 1. KHAI BÁO BIẾN sub Ở NGOÀI VÒNG LẶP ĐỂ KHÔNG BỊ LỖI UNDEFINED
  StreamSubscription? sub;

  final Uri wsUrl = Uri.parse('ws://$ip:81');
  debugPrint('[DEBUG_CONN] ==================================================');
  debugPrint('[DEBUG_CONN] 🚀 BẮT ĐẦU QUÁ TRÌNH KẾT NỐI TỚI: $wsUrl');

  for (int attempt = 1; attempt <= 3; attempt++) {
    debugPrint('[DEBUG_CONN] 🔄 [Lần $attempt/3] Đang thử kết nối WebSocket...');
    Completer<bool> connectionCompleter = Completer<bool>();

    try {
      channel = WebSocketChannel.connect(wsUrl);

      // Gán listener vào biến sub đã khai báo ở ngoài
      sub = channel.stream.listen(
        (data) {
          debugPrint('[DEBUG_CONN] 📥 Nhận tín hiệu từ ESP32: $data');
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

      isConnected = await connectionCompleter.future.timeout(
        const Duration(milliseconds: 3000),
        onTimeout: () {
          debugPrint('[DEBUG_CONN] ⚠️ [Lần $attempt/3] Hết thời gian chờ phản hồi!');
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

  // 🟢 2. XỬ LÝ CHUYỂN MÀNH HÌNH AN TOÀN
  if (isConnected && channel != null) {
    // HỦY BỎ SUBSCRIPTION CỦA CONNECT SCREEN TRƯỚC KHI TRUYỀN CHANNEL SANG MASTER SCREEN
    await sub?.cancel();
    sub = null;

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
          channel: channel!,
          ip: ip,
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
    _showErrorSnackBar('Không thể kết nối tới sa bàn ($ip). Vui lòng thử lại!');
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
    final TextEditingController titleController =
        TextEditingController(text: _appTitle);
    final TextEditingController urlController = TextEditingController(
        text: _bgImagePath.startsWith('http') ? _bgImagePath : '');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF0369A1)),
              SizedBox(width: 10),
              Text('Cập Nhật Màn Hình Chờ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        String cleanPath =
                            kIsWeb ? Uri.decodeFull(image.path) : image.path;
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
                          borderRadius: BorderRadius.circular(10)),
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
                                  'Đã khôi phục tiêu đề & ảnh gốc từ Cloud!'),
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
                          borderRadius: BorderRadius.circular(10)),
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
                        'saved_connect_bg', _parseDriveUrl(newUrl));
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
                        horizontal: 16.0, vertical: 8.0),
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
                        horizontal: 20.0, vertical: 18.0),
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
                            const Icon(Icons.tune_rounded,
                                color: Color(0xFF0369A1), size: 20),
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
                                color: Color(0xFF0369A1), fontSize: 13),
                            hintText: _selectedLang == 'vi'
        ? 'Ví dụ: saban-dongvancong.local hoặc saban-demo.onrender.com'
: 'e.g., saban-dongvancong.local or saban-demo.onrender.com',
                            prefixIcon: const Icon(Icons.wifi_rounded,
                                color: Color(0xFF0284C7), size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            filled: true,
                            fillColor: const Color(0xFFF0F9FF),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFFBAE6FD), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0284C7), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
              )
            : const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
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
              if (value == 'demo_mode') {
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
              } else if (value == 'upload_ota') {
                _uploadLocalBinToESP32();
              } else if (value == 'open_chrome_ota') {
                openWebOTAInChrome(_ipController.text.trim());
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'demo_mode',
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded,
                        color: Color(0xFF0284C7), size: 20),
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
                    const Icon(Icons.lan_rounded,
                        color: Colors.green, size: 20),
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
                    const Icon(Icons.open_in_browser_rounded,
                        color: Color(0xFF0284C7), size: 20),
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
                    const Icon(Icons.edit_note_rounded,
                        color: Color(0xFF0369A1), size: 20),
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
                    const Icon(Icons.download_for_offline_rounded,
                        color: Color(0xFF0284C7), size: 20),
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
                value: 'upload_ota',
                child: Row(
                  children: [
                    const Icon(Icons.system_update_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedLang == 'vi'
                            ? '2. Nạp file .bin vào ESP32 (Web OTA)'
                            : '2. Upload .bin to ESP32 (Web OTA)',
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
                    const Icon(Icons.chrome_reader_mode_rounded,
                        color: Colors.green, size: 20),
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
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
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
}