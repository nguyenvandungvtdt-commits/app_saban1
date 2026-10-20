// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:image_picker/image_picker.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:web_socket_channel/web_socket_channel.dart';
// // import 'master_control_screen.dart';
// // class ConnectScreen extends StatefulWidget {
// //   final String? autoConnectIp;
// //   const ConnectScreen({super.key, this.autoConnectIp});
// //   @override
// //   State<ConnectScreen> createState() => _ConnectScreenState();
// // }
// // class _ConnectScreenState extends State<ConnectScreen> {
// //   final TextEditingController _ipController =
// //       TextEditingController(text: '192.168.0.27');
// //   bool _isLoading = false;
// //   String _bgImagePath = 'assets/images/background.png';
// //   @override
// //   void initState() {
// //     super.initState();
// //     if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
// //       _ipController.text = widget.autoConnectIp!;
// //     }
// //   }
// //   bool _isValidServerAddress(String input) {
// //     if (input.trim().isEmpty) return false;
// //     final clean = input.trim();
// //     final ipRegExp = RegExp(
// //       r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
// //     );
// //     return ipRegExp.hasMatch(clean) ||
// //         clean.contains('.') ||
// //         clean.contains('localhost');
// //   }
// //   String _parseDriveUrl(String url) {
// //     if (url.trim().isEmpty) return url;
// //     String trimmed = url.trim();
// //     String? fileId;
// //     if (trimmed.contains('drive.google.com')) {
// //       if (trimmed.contains('/d/')) {
// //         fileId = trimmed.split('/d/')[1].split('/')[0].split('?')[0];
// //       } else if (trimmed.contains('id=')) {
// //         fileId = trimmed.split('id=')[1].split('&')[0];
// //       }
// //     }
// //     if (fileId != null && fileId.isNotEmpty) {
// //       return 'https://drive.google.com/uc?export=view&id=$fileId';
// //     }
// //     return trimmed;
// //   }
// //   Future<Map<String, dynamic>> _loadRemoteConfigFast() async {
// //     const String renderUrl = 'https://saban-demo.onrender.com/config';
// //     try {
// //       final response = await http
// //           .get(Uri.parse(renderUrl))
// //           .timeout(const Duration(seconds: 3));
// //       if (response.statusCode == 200) {
// //         final Map<String, dynamic> remoteData =
// //             jsonDecode(utf8.decode(response.bodyBytes));
// //         String? bgUrl = remoteData['assets']?['background'];
// //         if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
// //           _bgImagePath = _parseDriveUrl(bgUrl);
// //         }
// //         return remoteData;
// //       }
// //     } catch (e) {
// //       debugPrint('Tải Config từ Render gặp sự cố, thử kênh dự phòng: $e');
// //     }
// //     final String gistRawUrl =
// //         'https://gist.githubusercontent.com/nguyenvandungvtdt-commits/b3440aa5a5ab9e6e69bb570b389c88cb/raw/config.json?t=${DateTime.now().millisecondsSinceEpoch}';
// //     try {
// //       final response = await http
// //           .get(Uri.parse(gistRawUrl))
// //           .timeout(const Duration(milliseconds: 1800));
// //       if (response.statusCode == 200) {
// //         final Map<String, dynamic> remoteData =
// //             jsonDecode(utf8.decode(response.bodyBytes));
// //         String? bgUrl = remoteData['assets']?['background'];
// //         if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
// //           _bgImagePath = _parseDriveUrl(bgUrl);
// //         }
// //         return remoteData;
// //       }
// //     } catch (e) {
// //       debugPrint('Dùng Config nội bộ để tăng tốc: $e');
// //     }
// //     try {
// //       final String localJson =
// //           await rootBundle.loadString('assets/config.json');
// //       return jsonDecode(localJson);
// //     } catch (e) {
// //       return {};
// //     }
// //   }
// //   Future<void> _openWebDashboard() async {
// //     final Uri url = Uri.parse('https://saban-demo.onrender.com');
// //     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
// //       _showErrorSnackBar('Không thể mở trang web demo!');
// //     }
// //   }
// //   Future<void> _triggerFirmwareUpdate() async {
// //     final ip = _ipController.text.trim();
// //     if (!_isValidServerAddress(ip)) {
// //       _showErrorSnackBar(
// //           'Vui lòng nhập đúng IP/Địa chỉ của ESP32 trước khi nạp Firmware!');
// //       return;
// //     }
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Row(
// //           children: [
// //             SizedBox(
// //               width: 18,
// //               height: 18,
// //               child: CircularProgressIndicator(
// //                   color: Colors.white, strokeWidth: 2),
// //             ),
// //             SizedBox(width: 12),
// //             Text('Đang kiểm tra bản cập nhật Firmware từ Cloud...'),
// //           ],
// //         ),
// //         duration: Duration(seconds: 2),
// //       ),
// //     );
// //     try {
// //       String binUrl = '';
// //       String version = 'Mới nhất';
// //       try {
// //         final configData = await _loadRemoteConfigFast();
// //         final firmwareInfo = configData['firmware_info'];
// //         if (firmwareInfo != null && firmwareInfo['bin_url'] != null) {
// //           binUrl = firmwareInfo['bin_url'].toString().trim();
// //           version = firmwareInfo['version'] ?? 'Mới nhất';
// //         }
// //       } catch (_) {
// //         debugPrint(
// //             "Không lấy được từ Remote Config, thử gọi GitHub API trực tiếp...");
// //       }
// //       if (binUrl.isEmpty) {
// //         final releaseInfo = await fetchLatestRelease();
// //         if (releaseInfo != null) {
// //           binUrl = releaseInfo['download_url']!;
// //           version = releaseInfo['version']!;
// //         }
// //       }
// //       if (binUrl.isEmpty) {
// //         _showErrorSnackBar(
// //             'Không tìm thấy link Firmware trong cấu hình Cloud hoặc GitHub!');
// //         return;
// //       }
// //       if (!mounted) return;
// //       showDialog(
// //         context: context,
// //         builder: (dialogContext) {
// //           return AlertDialog(
// //             shape:
// //                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //             title: const Row(
// //               children: [
// //                 Icon(Icons.system_update_rounded, color: Color(0xFF0284C7)),
// //                 SizedBox(width: 10),
// //                 Text('Nâng Cấp Firmware ESP32',
// //                     style:
// //                         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //               ],
// //             ),
// //             content: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('• Phiên bản mới: v$version',
// //                     style: const TextStyle(fontWeight: FontWeight.bold)),
// //                 const SizedBox(height: 6),
// //                 Text(
// //                     '• Link tải: ${binUrl.substring(0, binUrl.length > 35 ? 35 : binUrl.length)}...'),
// //                 const SizedBox(height: 12),
// //                 const Text(
// //                   'ESP32 sẽ tự tải file .bin từ Cloud về tự ghi đè Flash và khởi động lại trong khoảng 15-20 giây. Bạn có muốn tiếp tục?',
// //                   style: TextStyle(fontSize: 13, color: Colors.black87),
// //                 ),
// //               ],
// //             ),
// //             actions: [
// //               TextButton(
// //                 onPressed: () => Navigator.pop(dialogContext),
// //                 child: const Text('Hủy'),
// //               ),
// //               ElevatedButton.icon(
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: const Color(0xFF0284C7),
// //                   foregroundColor: Colors.white,
// //                 ),
// //                 icon: const Icon(Icons.cloud_upload_rounded, size: 18),
// //                 label: const Text('Tiến Hành Nạp'),
// //                 onPressed: () async {
// //                   Navigator.pop(dialogContext);
// //                   _sendOTACmdToESP32(ip, binUrl, version);
// //                 },
// //               ),
// //             ],
// //           );
// //         },
// //       );
// //     } catch (e) {
// //       _showErrorSnackBar('Lỗi tải cấu hình Firmware: $e');
// //     }
// //   }
// //   Future<Map<String, String>?> fetchLatestRelease() async {
// //     final url = Uri.parse(
// //       'https://api.github.com/repos/nguyenvandungvtdt-commits/saban_firmware/releases/latest',
// //     );
// //     try {
// //       final response = await http.get(url);
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         String tagName = data['tag_name'] ?? '';
// //         List assets = data['assets'] ?? [];
// //         var binAsset = assets.firstWhere(
// //           (asset) => asset['name'].toString().endsWith('.bin'),
// //           orElse: () => null,
// //         );
// //         if (binAsset != null) {
// //           return {
// //             'version': tagName,
// //             'download_url': binAsset['browser_download_url'],
// //           };
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint("Lỗi lấy thông tin GitHub Release: $e");
// //     }
// //     return null;
// //   }
// //   Future<void> _sendOTACmdToESP32(String ip, String binUrl,
// //       [String version = '']) async {
// //     setState(() => _isLoading = true);
// //     double progressValue = 0.0;
// //     StateSetter? dialogSetState;
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (dialogContext) {
// //         return PopScope(
// //           canPop: false,
// //           child: StatefulBuilder(
// //             builder: (context, setStateDialog) {
// //               dialogSetState = setStateDialog;
// //               return AlertDialog(
// //                 shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(20)),
// //                 content: Padding(
// //                   padding: const EdgeInsets.symmetric(vertical: 10),
// //                   child: Column(
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       LinearProgressIndicator(
// //                         value: progressValue,
// //                         color: const Color(0xFF0284C7),
// //                         backgroundColor: Colors.grey[200],
// //                         minHeight: 8,
// //                         borderRadius: BorderRadius.circular(4),
// //                       ),
// //                       const SizedBox(height: 15),
// //                       Text(
// //                         version.isNotEmpty
// //                             ? 'ĐANG CẬP NHẬT FIRMWARE ($version)'
// //                             : 'ĐANG CẬP NHẬT FIRMWARE',
// //                         style: const TextStyle(
// //                             fontWeight: FontWeight.bold,
// //                             fontSize: 14,
// //                             color: Color(0xFF0369A1)),
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         '${(progressValue * 100).toInt()}% - Đang tải & nạp vào Flash...',
// //                         style:
// //                             const TextStyle(fontSize: 12, color: Colors.grey),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //         );
// //       },
// //     );
// //     try {
// //       final wsUrl = Uri.parse(
// //           ip.contains('onrender.com') ? 'wss://$ip' : 'ws://$ip:81');
// //       var channel = WebSocketChannel.connect(wsUrl);
// //       await channel.ready.timeout(const Duration(seconds: 5));
// //       String payload = version.isNotEmpty
// //           ? 'UPDATE_FIRMWARE:$binUrl|$version'
// //           : 'UPDATE_FIRMWARE:$binUrl';
// //       channel.sink.add(payload);
// //       await Future.delayed(const Duration(milliseconds: 300));
// //       await channel.sink.close();
// //     } catch (e) {
// //       debugPrint("Lỗi gửi lệnh WS: $e");
// //     }
// //     const int totalSeconds = 18;
// //     for (int i = 1; i <= totalSeconds; i++) {
// //       await Future.delayed(const Duration(seconds: 1));
// //       if (dialogSetState != null) {
// //         dialogSetState!(() {
// //           progressValue = i / totalSeconds;
// //         });
// //       }
// //     }
// //     bool isReconnected = false;
// //     for (int i = 0; i < 5; i++) {
// //       try {
// //         final testWs = WebSocketChannel.connect(Uri.parse(
// //             ip.contains('onrender.com') ? 'wss://$ip' : 'ws://$ip:81'));
// //         await testWs.ready.timeout(const Duration(seconds: 2));
// //         await testWs.sink.close();
// //         isReconnected = true;
// //         break;
// //       } catch (_) {
// //         await Future.delayed(const Duration(seconds: 1));
// //       }
// //     }
// //     if (!mounted) return;
// //     Navigator.of(context, rootNavigator: true).pop();
// //     setState(() => _isLoading = false);
// //     if (isReconnected) {
// //       _showOTASuccessDialog();
// //     } else {
// //       _showErrorSnackBar(
// //           'ESP32 chưa sẵn sàng. Hãy thử bấm Kết nối lại sau vài giây.');
// //     }
// //   }
// //   void _showOTASuccessDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           shape:
// //               RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //           title: const Row(
// //             children: [
// //               Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
// //               SizedBox(width: 10),
// //               Text('Cập Nhật Thành Công!',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             ],
// //           ),
// //           content: const Text(
// //             'Firmware mới đã được nạp thành công vào ESP32.\nMạch sa bàn đang tự khởi động lại và đã sẵn sàng hoạt động!',
// //             style: TextStyle(fontSize: 14),
// //           ),
// //           actions: [
// //             ElevatedButton(
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.green,
// //                 foregroundColor: Colors.white,
// //                 shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10)),
// //               ),
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text('ĐỒNG Ý'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //   void _connect() async {
// //     final ip = _ipController.text.trim();
// //     if (ip.isEmpty) {
// //       _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
// //       return;
// //     }
// //     if (!_isValidServerAddress(ip)) {
// //       _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
// //       return;
// //     }
// //     setState(() => _isLoading = true);
// //     try {
// //       Uri wsUrl;
// //       if (ip.contains('onrender.com') || ip.startsWith('wss://') || ip.startsWith('ws://')) {
// //         String formatted = ip;
// //         if (!formatted.startsWith('ws://') && !formatted.startsWith('wss://')) {
// //           formatted = 'wss://$formatted';
// //         }
// //         wsUrl = Uri.parse(formatted);
// //       } else {
// //         wsUrl = Uri.parse('ws://$ip:81');
// //       }
// //       final channel = WebSocketChannel.connect(wsUrl);
// //       final results = await Future.wait([
// //         channel.ready.timeout(
// //           const Duration(seconds: 4), // Timeout 4s hỗ trợ Render Cloud
// //           onTimeout: () => throw TimeoutException('Mất kết nối'),
// //         ),
// //         _loadRemoteConfigFast(),
// //       ]);
// //       final configData = results[1] as Map<String, dynamic>;
// //       if (!mounted) return;
// //       setState(() => _isLoading = false);
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => MasterControlScreen( channel: channel, ip: ip, configData: configData, ledStates: const {}, ),
// //         ),
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() => _isLoading = false);
// //       _showErrorSnackBar(
// //           'Không thể kết nối tới sa bàn ($ip). Vui lòng kiểm tra lại IP hoặc Wi-Fi!');
// //     }
// //   }
// //   void _showErrorSnackBar(String message) {
// //     ScaffoldMessenger.of(context).clearSnackBars();
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Row(
// //           children: [
// //             const Icon(Icons.error_outline_rounded, color: Colors.white),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Text(
// //                 message,
// //                 style: const TextStyle(fontWeight: FontWeight.w600),
// //               ),
// //             ),
// //           ],
// //         ),
// //         backgroundColor: Colors.redAccent,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //         duration: const Duration(seconds: 3),
// //       ),
// //     );
// //   }
// //   void _showImageEditDialog(BuildContext context) {
// //     final TextEditingController urlController = TextEditingController(
// //         text: _bgImagePath.startsWith('http') ? _bgImagePath : '');
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           shape:
// //               RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //           title: const Row(
// //             children: [
// //               Icon(Icons.add_a_photo_rounded, color: Color(0xFF0369A1)),
// //               SizedBox(width: 10),
// //               Text('Cập Nhật Ảnh Banner',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             ],
// //           ),
// //           content: SingleChildScrollView(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 TextField(
// //                   controller: urlController,
// //                   decoration: const InputDecoration(
// //                     labelText: 'Link Ảnh Google Drive / Online',
// //                     hintText: 'Dán link Google Drive vào đây...',
// //                     prefixIcon: Icon(Icons.link_rounded),
// //                     border: OutlineInputBorder(),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 const Row(
// //                   children: [
// //                     Expanded(child: Divider()),
// //                     Padding(
// //                       padding: EdgeInsets.symmetric(horizontal: 8.0),
// //                       child: Text('HOẶC',
// //                           style: TextStyle(color: Colors.grey, fontSize: 12)),
// //                     ),
// //                     Expanded(child: Divider()),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 16),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: () async {
// //                       final ImagePicker picker = ImagePicker();
// //                       final XFile? image = await picker.pickImage(
// //                         source: ImageSource.gallery,
// //                       );
// //                       if (image != null) {
// //                         setState(() {
// //                           _bgImagePath = image.path;
// //                         });
// //                         if (context.mounted) Navigator.pop(context);
// //                       }
// //                     },
// //                     icon: const Icon(Icons.photo_library_rounded),
// //                     label: const Text('Tải ảnh từ Thư viện'),
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 12),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text('Hủy'),
// //             ),
// //             ElevatedButton(
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF0284C7),
// //                 foregroundColor: Colors.white,
// //               ),
// //               onPressed: () {
// //                 if (urlController.text.trim().isNotEmpty) {
// //                   setState(() {
// //                     _bgImagePath = _parseDriveUrl(urlController.text);
// //                   });
// //                 }
// //                 Navigator.pop(context);
// //               },
// //               child: const Text('Áp Dụng'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         fit: StackFit.expand,
// //         children: [
// //           Container(
// //             decoration: const BoxDecoration(
// //               gradient: LinearGradient(
// //                 begin: Alignment.topCenter,
// //                 end: Alignment.bottomCenter,
// //                 colors: [ Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFF8FAFC), ],
// //               ),
// //             ),
// //           ),
// //           SafeArea(
// //             child: Column(
// //               children: [
// //                 _buildTopBar(context),
// //                 Expanded(
// //                   child: Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                         horizontal: 16.0, vertical: 8.0),
// //                     child: Center(
// //                       child: Container(
// //                         decoration: BoxDecoration(
// //                           borderRadius: BorderRadius.circular(20),
// //                           boxShadow: [ BoxShadow( color: const Color(0xFF0284C7) .withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 1, offset: const Offset(0, 8), ), ],
// //                         ),
// //                         child: ClipRRect(
// //                           borderRadius: BorderRadius.circular(20),
// //                           child: _bgImagePath.startsWith('http')
// //                               ? Image.network(
// //                                   _bgImagePath,
// //                                   fit: BoxFit.contain,
// //                                   loadingBuilder: (context, child, progress) {
// //                                     if (progress == null) return child;
// //                                     return const Center(
// //                                       child: CircularProgressIndicator(
// //                                           color: Color(0xFF0284C7)),
// //                                     );
// //                                   },
// //                                   errorBuilder: (context, error, stackTrace) =>
// //                                       Image.asset(
// //                                     'assets/images/background.png',
// //                                     fit: BoxFit.contain,
// //                                     errorBuilder:
// //                                         (context, error, stackTrace) =>
// //                                             Container(
// //                                                 color: const Color(0xFFBAE6FD)),
// //                                   ),
// //                                 )
// //                               : Image.asset(
// //                                   _bgImagePath,
// //                                   fit: BoxFit.contain,
// //                                   errorBuilder: (context, error, stackTrace) =>
// //                                       Container(
// //                                           color: const Color(0xFFBAE6FD)),
// //                                 ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 Padding(
// //                   padding: const EdgeInsets.all(16.0),
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(
// //                         horizontal: 20.0, vertical: 18.0),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white.withValues(alpha: 0.92),
// //                       borderRadius: BorderRadius.circular(22),
// //                       border: Border.all(
// //                         color: const Color(0xFFBAE6FD),
// //                         width: 1.5,
// //                       ),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: const Color(0xFF0284C7)
// //                               .withValues(alpha: 0.12),
// //                           blurRadius: 20,
// //                           offset: const Offset(0, 6),
// //                         ),
// //                       ],
// //                     ),
// //                     child: Column(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         const Row(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Icon(Icons.tune_rounded,
// //                                 color: Color(0xFF0369A1), size: 20),
// //                             SizedBox(width: 8),
// //                             Text(
// //                               'ĐIỀU KHIỂN SA BÀN THÔNG MINH',
// //                               style: TextStyle(
// //                                 fontSize: 14,
// //                                 fontWeight: FontWeight.bold,
// //                                 color: Color(0xFF0369A1),
// //                                 letterSpacing: 0.8,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 14),
// //                         TextField(
// //                           controller: _ipController,
// //                           keyboardType: TextInputType.url,
// //                           style: const TextStyle(
// //                             fontSize: 15,
// //                             fontWeight: FontWeight.bold,
// //                             color: Color(0xFF0F172A),
// //                           ),
// //                           decoration: InputDecoration(
// //                             labelText: 'Địa chỉ IP / Server Sa bàn',
// //                             labelStyle: const TextStyle(
// //                                 color: Color(0xFF0369A1), fontSize: 13),
// //                             hintText: 'VD: 192.168.0.27 hoặc saban-demo.onrender.com',
// //                             prefixIcon: const Icon(Icons.wifi_rounded,
// //                                 color: Color(0xFF0284C7), size: 20),
// //                             contentPadding: const EdgeInsets.symmetric(
// //                                 vertical: 12, horizontal: 16),
// //                             filled: true,
// //                             fillColor: const Color(0xFFF0F9FF),
// //                             enabledBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                               borderSide: const BorderSide(
// //                                   color: Color(0xFFBAE6FD), width: 1.2),
// //                             ),
// //                             focusedBorder: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(12),
// //                               borderSide: const BorderSide(
// //                                   color: Color(0xFF0284C7), width: 2),
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 14),
// //                         SizedBox(
// //                           width: double.infinity,
// //                           height: 48,
// //                           child: InkWell(
// //                             onTap: _isLoading ? null : _connect,
// //                             borderRadius: BorderRadius.circular(12),
// //                             child: AnimatedContainer(
// //                               duration: const Duration(milliseconds: 200),
// //                               decoration: BoxDecoration(
// //                                 gradient: _isLoading
// //                                     ? const LinearGradient(colors: [ Color(0xFF94A3B8), Color(0xFF64748B) ])
// //                                     : const LinearGradient(
// //                                         colors: [ Color(0xFF0284C7), Color(0xFF0369A1) ],
// //                                         begin: Alignment.topLeft,
// //                                         end: Alignment.bottomRight,
// //                                       ),
// //                                 borderRadius: BorderRadius.circular(12),
// //                                 boxShadow: [ BoxShadow( color: const Color(0xFF0284C7) .withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4), ), ],
// //                               ),
// //                               child: Center(
// //                                 child: _isLoading
// //                                     ? const Row(
// //                                         mainAxisAlignment:
// //                                             MainAxisAlignment.center,
// //                                         children: [
// //                                           SizedBox( width: 18, height: 18, child: CircularProgressIndicator( color: Colors.white, strokeWidth: 2, ), ),
// //                                           SizedBox(width: 10),
// //                                           Text(
// //                                             'Đang kết nối, vui lòng chờ chút ạ!',
// //                                             style: TextStyle(
// //                                               color: Colors.white,
// //                                               fontWeight: FontWeight.bold,
// //                                               fontSize: 14,
// //                                             ),
// //                                           ),
// //                                         ],
// //                                       )
// //                                     : const Row(
// //                                         mainAxisAlignment:
// //                                             MainAxisAlignment.center,
// //                                         children: [
// //                                           Icon( Icons.power_settings_new_rounded, color: Colors.white, size: 18),
// //                                           SizedBox(width: 8),
// //                                           Text( 'KẾT NỐI VÀ TẢI SA BÀN', style: TextStyle( color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8, ), ),
// //                                         ],
// //                                       ),
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //   Widget _buildTopBar(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Container(
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               color: Colors.white.withValues(alpha: 0.9),
// //               boxShadow: [ BoxShadow( color: const Color(0xFF0284C7).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3), ), ],
// //             ),
// //             child: PopupMenuButton<String>(
// //               icon: const Icon(Icons.menu_rounded,
// //                   color: Color(0xFF0369A1), size: 22),
// //               shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(16)),
// //               onSelected: (value) {
// //                 if (value == 'demo_mode') {
// //                   setState(() {
// //                     _ipController.text = 'saban-demo.onrender.com';
// //                   });
// //                   _connect();
// //                 } else if (value == 'real_mode') {
// //                   setState(() {
// //                     _ipController.text = '192.168.0.27';
// //                   });
// //                   _connect();
// //                 } else if (value == 'web_demo') {
// //                   _openWebDashboard();
// //                 } else if (value == 'cloud') {
// //                   _loadRemoteConfigFast();
// //                 } else if (value == 'edit_image') {
// //                   _showImageEditDialog(context);
// //                 } else if (value == 'update_firmware') {
// //                   _triggerFirmwareUpdate();
// //                 }
// //               },
// //               itemBuilder: (BuildContext context) => [
// //                 const PopupMenuItem(
// //                   value: 'demo_mode',
// //                   child: Row(
// //                     children: [ Icon(Icons.cloud_done_rounded, color: Color(0xFF0284C7), size: 20), SizedBox(width: 10), Text('Dùng Sa Bàn Demo Cloud', style: TextStyle(fontWeight: FontWeight.bold)), ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: 'real_mode',
// //                   child: Row(
// //                     children: [ Icon(Icons.lan_rounded, color: Colors.green, size: 20), SizedBox(width: 10), Text('Dùng Sa Bàn Thực (Mạng LAN)'), ],
// //                   ),
// //                 ),
// //                 const PopupMenuDivider(),
// //                 const PopupMenuItem(
// //                   value: 'web_demo',
// //                   child: Row(
// //                     children: [ Icon(Icons.open_in_browser_rounded, color: Color(0xFF0284C7), size: 20), SizedBox(width: 10), Text('Xem Sa Bàn Web (Live Demo)'), ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: 'cloud',
// //                   child: Row(
// //                     children: [ Icon(Icons.cloud_download_outlined, color: Color(0xFF0284C7), size: 20), SizedBox(width: 10), Text('Đồng bộ dữ liệu Cloud'), ],
// //                   ),
// //                 ),
// //                 const PopupMenuItem(
// //                   value: 'edit_image',
// //                   child: Row(
// //                     children: [ Icon(Icons.add_a_photo_outlined, color: Color(0xFF0284C7), size: 20), SizedBox(width: 10), Text('Đổi / Tải ảnh Banner lên'), ],
// //                   ),
// //                 ),
// //                 const PopupMenuDivider(),
// //                 const PopupMenuItem(
// //                   value: 'update_firmware',
// //                   child: Row(
// //                     children: [
// //                       Icon(Icons.system_update_alt_rounded,
// //                           color: Colors.orange, size: 20),
// //                       SizedBox(width: 10),
// //                       Text('Nạp Firmware ESP32 (Auto OTA)',
// //                           style: TextStyle(fontWeight: FontWeight.bold)),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //             decoration: BoxDecoration(
// //               color: Colors.white.withValues(alpha: 0.9),
// //               borderRadius: BorderRadius.circular(20),
// //               border: Border.all(color: const Color(0xFFBAE6FD)),
// //               boxShadow: [ BoxShadow( color: const Color(0xFF0284C7).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2), ), ],
// //             ),
// //             child: const Row(
// //               children: [ CircleAvatar(radius: 4, backgroundColor: Colors.green), SizedBox(width: 6), Text( 'HỆ THỐNG SẴN SÀNG', style: TextStyle( fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1), ), ), ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }


// import 'dart:async';
// import 'dart:convert';
// // import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../widgets/dynamic_image.dart'; // 🟢 Dùng DynamicImage widget đa nền tảng
// import 'master_control_screen.dart';

// class ConnectScreen extends StatefulWidget {
//   final String? autoConnectIp;
//   const ConnectScreen({super.key, this.autoConnectIp});

//   @override
//   State<ConnectScreen> createState() => _ConnectScreenState();
// }

// class _ConnectScreenState extends State<ConnectScreen> {
//   final TextEditingController _ipController =
//       TextEditingController(text: '192.168.0.27');
//   bool _isLoading = false;

//   // 🟢 State lưu Tiêu đề và Ảnh Banner màn hình Connect
//   String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
//   String _bgImagePath = 'assets/images/background.png';

//   @override
//   void initState() {
//     super.initState();
//     if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
//       _ipController.text = widget.autoConnectIp!;
//     }
//     _loadSavedPreferences();
//   }

//   // 🟢 Đọc Tên App & Ảnh Banner đã lưu từ bộ nhớ máy
//   Future<void> _loadSavedPreferences() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? savedTitle = prefs.getString('saved_connect_title');
//       String? savedBg = prefs.getString('saved_connect_bg');

//       if (mounted) {
//         setState(() {
//           if (savedTitle != null && savedTitle.isNotEmpty) {
//             _appTitle = savedTitle;
//           }
//           if (savedBg != null && savedBg.isNotEmpty) {
//             _bgImagePath = savedBg;
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint("Lỗi nạp SharedPreferences ConnectScreen: $e");
//     }
//   }

//   bool _isValidServerAddress(String input) {
//     if (input.trim().isEmpty) return false;
//     final clean = input.trim();
//     final ipRegExp = RegExp(
//       r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
//     );
//     return ipRegExp.hasMatch(clean) ||
//         clean.contains('.') ||
//         clean.contains('localhost');
//   }

//   String _parseDriveUrl(String url) {
//     if (url.trim().isEmpty) return url;
//     String trimmed = url.trim();
//     String? fileId;
//     if (trimmed.contains('drive.google.com')) {
//       if (trimmed.contains('/d/')) {
//         fileId = trimmed.split('/d/')[1].split('/')[0].split('?')[0];
//       } else if (trimmed.contains('id=')) {
//         fileId = trimmed.split('id=')[1].split('&')[0];
//       }
//     }
//     if (fileId != null && fileId.isNotEmpty) {
//       return 'https://drive.google.com/uc?export=view&id=$fileId';
//     }
//     return trimmed;
//   }

//   Future<Map<String, dynamic>> _loadRemoteConfigFast() async {
//     const String renderUrl = 'https://saban-demo.onrender.com/config';
//     try {
//       final response = await http
//           .get(Uri.parse(renderUrl))
//           .timeout(const Duration(seconds: 3));
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> remoteData =
//             jsonDecode(utf8.decode(response.bodyBytes));
        
//         // Cập nhật Ảnh từ Cloud nếu người dùng CHƯA lưu ảnh cá nhân
//         final prefs = await SharedPreferences.getInstance();
//         if (!prefs.containsKey('saved_connect_bg')) {
//           String? bgUrl = remoteData['assets']?['background'];
//           if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
//             setState(() {
//               _bgImagePath = _parseDriveUrl(bgUrl);
//             });
//           }
//         }
//         return remoteData;
//       }
//     } catch (e) {
//       debugPrint('Tải Config từ Render gặp sự cố, thử kênh dự phòng: $e');
//     }

//     final String gistRawUrl =
//         'https://gist.githubusercontent.com/nguyenvandungvtdt-commits/b3440aa5a5ab9e6e69bb570b389c88cb/raw/config.json?t=${DateTime.now().millisecondsSinceEpoch}';
//     try {
//       final response = await http
//           .get(Uri.parse(gistRawUrl))
//           .timeout(const Duration(milliseconds: 1800));
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> remoteData =
//             jsonDecode(utf8.decode(response.bodyBytes));
//         final prefs = await SharedPreferences.getInstance();
//         if (!prefs.containsKey('saved_connect_bg')) {
//           String? bgUrl = remoteData['assets']?['background'];
//           if (bgUrl != null && bgUrl.isNotEmpty && mounted) {
//             setState(() {
//               _bgImagePath = _parseDriveUrl(bgUrl);
//             });
//           }
//         }
//         return remoteData;
//       }
//     } catch (e) {
//       debugPrint('Dùng Config nội bộ để tăng tốc: $e');
//     }

//     try {
//       final String localJson =
//           await rootBundle.loadString('assets/config.json');
//       return jsonDecode(localJson);
//     } catch (e) {
//       return {};
//     }
//   }

//   Future<void> _openWebDashboard() async {
//     final Uri url = Uri.parse('https://saban-demo.onrender.com');
//     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
//       _showErrorSnackBar('Không thể mở trang web demo!');
//     }
//   }

//   Future<void> _triggerFirmwareUpdate() async {
//     final ip = _ipController.text.trim();
//     if (!_isValidServerAddress(ip)) {
//       _showErrorSnackBar(
//           'Vui lòng nhập đúng IP/Địa chỉ của ESP32 trước khi nạp Firmware!');
//       return;
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             SizedBox(
//               width: 18,
//               height: 18,
//               child: CircularProgressIndicator(
//                   color: Colors.white, strokeWidth: 2),
//             ),
//             SizedBox(width: 12),
//             Text('Đang kiểm tra bản cập nhật Firmware từ Cloud...'),
//           ],
//         ),
//         duration: Duration(seconds: 2),
//       ),
//     );
//     try {
//       String binUrl = '';
//       String version = 'Mới nhất';
//       try {
//         final configData = await _loadRemoteConfigFast();
//         final firmwareInfo = configData['firmware_info'];
//         if (firmwareInfo != null && firmwareInfo['bin_url'] != null) {
//           binUrl = firmwareInfo['bin_url'].toString().trim();
//           version = firmwareInfo['version'] ?? 'Mới nhất';
//         }
//       } catch (_) {
//         debugPrint(
//             "Không lấy được từ Remote Config, thử gọi GitHub API trực tiếp...");
//       }
//       if (binUrl.isEmpty) {
//         final releaseInfo = await fetchLatestRelease();
//         if (releaseInfo != null) {
//           binUrl = releaseInfo['download_url']!;
//           version = releaseInfo['version']!;
//         }
//       }
//       if (binUrl.isEmpty) {
//         _showErrorSnackBar(
//             'Không tìm thấy link Firmware trong cấu hình Cloud hoặc GitHub!');
//         return;
//       }
//       if (!mounted) return;
//       showDialog(
//         context: context,
//         builder: (dialogContext) {
//           return AlertDialog(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: const Row(
//               children: [
//                 Icon(Icons.system_update_rounded, color: Color(0xFF0284C7)),
//                 SizedBox(width: 10),
//                 Text('Nâng Cấp Firmware ESP32',
//                     style:
//                         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('• Phiên bản mới: v$version',
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 6),
//                 Text(
//                     '• Link tải: ${binUrl.substring(0, binUrl.length > 35 ? 35 : binUrl.length)}...'),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'ESP32 sẽ tự tải file .bin từ Cloud về tự ghi đè Flash và khởi động lại trong khoảng 15-20 giây. Bạn có muốn tiếp tục?',
//                   style: TextStyle(fontSize: 13, color: Colors.black87),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(dialogContext),
//                 child: const Text('Hủy'),
//               ),
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF0284C7),
//                   foregroundColor: Colors.white,
//                 ),
//                 icon: const Icon(Icons.cloud_upload_rounded, size: 18),
//                 label: const Text('Tiến Hành Nạp'),
//                 onPressed: () async {
//                   Navigator.pop(dialogContext);
//                   _sendOTACmdToESP32(ip, binUrl, version);
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       _showErrorSnackBar('Lỗi tải cấu hình Firmware: $e');
//     }
//   }

//   Future<Map<String, String>?> fetchLatestRelease() async {
//     final url = Uri.parse(
//       'https://api.github.com/repos/nguyenvandungvtdt-commits/saban_firmware/releases/latest',
//     );
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         String tagName = data['tag_name'] ?? '';
//         List assets = data['assets'] ?? [];
//         var binAsset = assets.firstWhere(
//           (asset) => asset['name'].toString().endsWith('.bin'),
//           orElse: () => null,
//         );
//         if (binAsset != null) {
//           return {
//             'version': tagName,
//             'download_url': binAsset['browser_download_url'],
//           };
//         }
//       }
//     } catch (e) {
//       debugPrint("Lỗi lấy thông tin GitHub Release: $e");
//     }
//     return null;
//   }

//   Future<void> _sendOTACmdToESP32(String ip, String binUrl,
//       [String version = '']) async {
//     setState(() => _isLoading = true);
//     double progressValue = 0.0;
//     StateSetter? dialogSetState;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return PopScope(
//           canPop: false,
//           child: StatefulBuilder(
//             builder: (context, setStateDialog) {
//               dialogSetState = setStateDialog;
//               return AlertDialog(
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20)),
//                 content: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       LinearProgressIndicator(
//                         value: progressValue,
//                         color: const Color(0xFF0284C7),
//                         backgroundColor: Colors.grey[200],
//                         minHeight: 8,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       const SizedBox(height: 15),
//                       Text(
//                         version.isNotEmpty
//                             ? 'ĐANG CẬP NHẬT FIRMWARE ($version)'
//                             : 'ĐANG CẬP NHẬT FIRMWARE',
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                             color: Color(0xFF0369A1)),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         '${(progressValue * 100).toInt()}% - Đang tải & nạp vào Flash...',
//                         style:
//                             const TextStyle(fontSize: 12, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//     try {
//       final wsUrl = Uri.parse(
//           ip.contains('onrender.com') ? 'wss://$ip' : 'ws://$ip:81');
//       var channel = WebSocketChannel.connect(wsUrl);
//       await channel.ready.timeout(const Duration(seconds: 5));
//       String payload = version.isNotEmpty
//           ? 'UPDATE_FIRMWARE:$binUrl|$version'
//           : 'UPDATE_FIRMWARE:$binUrl';
//       channel.sink.add(payload);
//       await Future.delayed(const Duration(milliseconds: 300));
//       await channel.sink.close();
//     } catch (e) {
//       debugPrint("Lỗi gửi lệnh WS: $e");
//     }
//     const int totalSeconds = 18;
//     for (int i = 1; i <= totalSeconds; i++) {
//       await Future.delayed(const Duration(seconds: 1));
//       if (dialogSetState != null) {
//         dialogSetState!(() {
//           progressValue = i / totalSeconds;
//         });
//       }
//     }
//     bool isReconnected = false;
//     for (int i = 0; i < 5; i++) {
//       try {
//         final testWs = WebSocketChannel.connect(Uri.parse(
//             ip.contains('onrender.com') ? 'wss://$ip' : 'ws://$ip:81'));
//         await testWs.ready.timeout(const Duration(seconds: 2));
//         await testWs.sink.close();
//         isReconnected = true;
//         break;
//       } catch (_) {
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }
//     if (!mounted) return;
//     Navigator.of(context, rootNavigator: true).pop();
//     setState(() => _isLoading = false);
//     if (isReconnected) {
//       _showOTASuccessDialog();
//     } else {
//       _showErrorSnackBar(
//           'ESP32 chưa sẵn sàng. Hãy thử bấm Kết nối lại sau vài giây.');
//     }
//   }

//   void _showOTASuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
//               SizedBox(width: 10),
//               Text('Cập Nhật Thành Công!',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: const Text(
//             'Firmware mới đã được nạp thành công vào ESP32.\nMạch sa bàn đang tự khởi động lại và đã sẵn sàng hoạt động!',
//             style: TextStyle(fontSize: 14),
//           ),
//           actions: [
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10)),
//               ),
//               onPressed: () => Navigator.pop(context),
//               child: const Text('ĐỒNG Ý'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _connect() async {
//     final ip = _ipController.text.trim();
//     if (ip.isEmpty) {
//       _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
//       return;
//     }
//     if (!_isValidServerAddress(ip)) {
//       _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
//       return;
//     }
//     setState(() => _isLoading = true);
//     try {
//       Uri wsUrl;
//       if (ip.contains('onrender.com') || ip.startsWith('wss://') || ip.startsWith('ws://')) {
//         String formatted = ip;
//         if (!formatted.startsWith('ws://') && !formatted.startsWith('wss://')) {
//           formatted = 'wss://$formatted';
//         }
//         wsUrl = Uri.parse(formatted);
//       } else {
//         wsUrl = Uri.parse('ws://$ip:81');
//       }
//       final channel = WebSocketChannel.connect(wsUrl);
//       final results = await Future.wait([
//         channel.ready.timeout(
//           const Duration(seconds: 4),
//           onTimeout: () => throw TimeoutException('Mất kết nối'),
//         ),
//         _loadRemoteConfigFast(),
//       ]);
//       final configData = results[1] as Map<String, dynamic>;
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MasterControlScreen(
//             channel: channel,
//             ip: ip,
//             configData: configData,
//             ledStates: const {},
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showErrorSnackBar(
//           'Không thể kết nối tới sa bàn ($ip). Vui lòng kiểm tra lại IP hoặc Wi-Fi!');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline_rounded, color: Colors.white),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // 🟢 DIALOG ĐỔI TÊN APP & ẢNH BANNER MÀN HÌNH CONNECT
//   void _showImageEditDialog(BuildContext context) {
//     final TextEditingController titleController =
//         TextEditingController(text: _appTitle);
//     final TextEditingController urlController = TextEditingController(
//         text: _bgImagePath.startsWith('http') ? _bgImagePath : '');

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Row(
//             children: [
//               Icon(Icons.edit_note_rounded, color: Color(0xFF0369A1)),
//               SizedBox(width: 10),
//               Text('Cập Nhật Màn Hình Chờ',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // 1. Chỉnh sửa Tiêu đề App
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Tiêu Đề Ứng Dụng',
//                     prefixIcon: Icon(Icons.title_rounded),
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // 2. Chỉnh sửa URL Ảnh Banner
//                 TextField(
//                   controller: urlController,
//                   decoration: const InputDecoration(
//                     labelText: 'Link Ảnh Google Drive / Direct URL',
//                     hintText: 'Dán link Google Drive/Web...',
//                     prefixIcon: Icon(Icons.link_rounded),
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 14),

//                 // 3. Nút Chọn Ảnh từ Thư Viện Cục Bộ
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       try {
//                         final ImagePicker picker = ImagePicker();
//                         final XFile? image = await picker.pickImage(
//                           source: ImageSource.gallery,
//                           imageQuality: 85,
//                         );

//                         if (image == null) return;
//                         String cleanPath =
//                             kIsWeb ? Uri.decodeFull(image.path) : image.path;

//                         if (mounted) {
//                           setState(() {
//                             _bgImagePath = cleanPath;
//                           });

//                           final prefs = await SharedPreferences.getInstance();
//                           await prefs.setString('saved_connect_bg', cleanPath);
//                         }

//                         if (dialogContext.mounted) {
//                           Navigator.pop(dialogContext);
//                         }
//                       } catch (e) {
//                         debugPrint("❌ Lỗi chọn ảnh banner: $e");
//                       }
//                     },
//                     icon: const Icon(Icons.photo_library_rounded),
//                     label: const Text('Chọn ảnh từ Thư viện'),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 // 4. 🟢 NÚT KHÔI PHỤC VỀ DỮ LIỆU CLOUD MẶC ĐỊNH
//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       try {
//                         final prefs = await SharedPreferences.getInstance();
//                         await prefs.remove('saved_connect_title');
//                         await prefs.remove('saved_connect_bg');

//                         if (mounted) {
//                           setState(() {
//                             _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
//                             _bgImagePath = 'assets/images/background.png';
//                           });
//                         }

//                         // Gọi nạp lại config online nếu có
//                         _loadRemoteConfigFast();

//                         if (dialogContext.mounted) {
//                           Navigator.pop(dialogContext);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                   'Đã khôi phục tiêu đề & ảnh gốc từ Cloud!'),
//                               duration: Duration(seconds: 2),
//                             ),
//                           );
//                         }
//                       } catch (e) {
//                         debugPrint("❌ Lỗi khôi phục banner: $e");
//                       }
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.orange,
//                       side: const BorderSide(color: Colors.orange),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                     icon: const Icon(Icons.refresh_rounded, size: 20),
//                     label: const Text(
//                       'Khôi phục gốc từ Cloud',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Hủy'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF0284C7),
//                 foregroundColor: Colors.white,
//               ),
//               onPressed: () async {
//                 String newTitle = titleController.text.trim();
//                 String newUrl = urlController.text.trim();

//                 final prefs = await SharedPreferences.getInstance();

//                 if (mounted) {
//                   setState(() {
//                     if (newTitle.isNotEmpty) {
//                       _appTitle = newTitle;
//                     }
//                     if (newUrl.isNotEmpty) {
//                       _bgImagePath = _parseDriveUrl(newUrl);
//                     }
//                   });

//                   if (newTitle.isNotEmpty) {
//                     await prefs.setString('saved_connect_title', newTitle);
//                   }
//                   if (newUrl.isNotEmpty) {
//                     await prefs.setString(
//                         'saved_connect_bg', _parseDriveUrl(newUrl));
//                   }
//                 }
//                  if (dialogContext.mounted) {
//       Navigator.pop(dialogContext);
//     }
//               },
//               child: const Text('Áp Dụng'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFFF0F9FF),
//                   Color(0xFFE0F2FE),
//                   Color(0xFFF8FAFC),
//                 ],
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildTopBar(context),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16.0, vertical: 8.0),
//                     child: Center(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF0284C7)
//                                   .withValues(alpha: 0.2),
//                               blurRadius: 24,
//                               spreadRadius: 1,
//                               offset: const Offset(0, 8),
//                             ),
//                           ],
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(20),
//                           // 🟢 2. Dùng DynamicImage render Ảnh Banner tự động tương thích 4 nguồn ảnh
//                           child: DynamicImage(
//                             imagePath: _bgImagePath,
//                             fit: BoxFit.contain,
//                             fallbackAsset: 'assets/images/background.png',
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20.0, vertical: 18.0),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withValues(alpha: 0.92),
//                       borderRadius: BorderRadius.circular(22),
//                       border: Border.all(
//                         color: const Color(0xFFBAE6FD),
//                         width: 1.5,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFF0284C7)
//                               .withValues(alpha: 0.12),
//                           blurRadius: 20,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // 🟢 Hiển thị Tên App có thể chỉnh sửa tự do
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.tune_rounded,
//                                 color: Color(0xFF0369A1), size: 20),
//                             const SizedBox(width: 8),
//                             Flexible(
//                               child: Text(
//                                 _appTitle,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF0369A1),
//                                   letterSpacing: 0.8,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 14),
//                         TextField(
//                           controller: _ipController,
//                           keyboardType: TextInputType.url,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF0F172A),
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Địa chỉ IP / Server Sa bàn',
//                             labelStyle: const TextStyle(
//                                 color: Color(0xFF0369A1), fontSize: 13),
//                             hintText:
//                                 'VD: 192.168.0.27 hoặc saban-demo.onrender.com',
//                             prefixIcon: const Icon(Icons.wifi_rounded,
//                                 color: Color(0xFF0284C7), size: 20),
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 12, horizontal: 16),
//                             filled: true,
//                             fillColor: const Color(0xFFF0F9FF),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                   color: Color(0xFFBAE6FD), width: 1.2),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(
//                                   color: Color(0xFF0284C7), width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 14),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 48,
//                           child: InkWell(
//                             onTap: _isLoading ? null : _connect,
//                             borderRadius: BorderRadius.circular(12),
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               decoration: BoxDecoration(
//                                 gradient: _isLoading
//                                     ? const LinearGradient(colors: [
//                                         Color(0xFF94A3B8),
//                                         Color(0xFF64748B)
//                                       ])
//                                     : const LinearGradient(
//                                         colors: [
//                                           Color(0xFF0284C7),
//                                           Color(0xFF0369A1)
//                                         ],
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                       ),
//                                 borderRadius: BorderRadius.circular(12),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: const Color(0xFF0284C7)
//                                         .withValues(alpha: 0.3),
//                                     blurRadius: 12,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               child: Center(
//                                 child: _isLoading
//                                     ? const Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           SizedBox(
//                                             width: 18,
//                                             height: 18,
//                                             child: CircularProgressIndicator(
//                                               color: Colors.white,
//                                               strokeWidth: 2,
//                                             ),
//                                           ),
//                                           SizedBox(width: 10),
//                                           Text(
//                                             'Đang kết nối, vui lòng chờ chút ạ!',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                         ],
//                                       )
//                                     : const Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Icon(
//                                               Icons.power_settings_new_rounded,
//                                               color: Colors.white,
//                                               size: 18),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'KẾT NỐI VÀ TẢI SA BÀN',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 14,
//                                               fontWeight: FontWeight.bold,
//                                               letterSpacing: 0.8,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withValues(alpha: 0.9),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: PopupMenuButton<String>(
//               icon: const Icon(Icons.menu_rounded,
//                   color: Color(0xFF0369A1), size: 22),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16)),
//               onSelected: (value) {
//                 if (value == 'demo_mode') {
//                   setState(() {
//                     _ipController.text = 'saban-demo.onrender.com';
//                   });
//                   _connect();
//                 } else if (value == 'real_mode') {
//                   setState(() {
//                     _ipController.text = '192.168.0.27';
//                   });
//                   _connect();
//                 } else if (value == 'web_demo') {
//                   _openWebDashboard();
//                 } else if (value == 'cloud') {
//                   _loadRemoteConfigFast();
//                 } else if (value == 'edit_image') {
//                   _showImageEditDialog(context);
//                 } else if (value == 'update_firmware') {
//                   _triggerFirmwareUpdate();
//                 }
//               },
//               itemBuilder: (BuildContext context) => [
//                 const PopupMenuItem(
//                   value: 'demo_mode',
//                   child: Row(
//                     children: [
//                       Icon(Icons.cloud_done_rounded,
//                           color: Color(0xFF0284C7), size: 20),
//                       SizedBox(width: 10),
//                       Text('Dùng Sa Bàn Demo Cloud',
//                           style: TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'real_mode',
//                   child: Row(
//                     children: [
//                       Icon(Icons.lan_rounded, color: Colors.green, size: 20),
//                       SizedBox(width: 10),
//                       Text('Dùng Sa Bàn Thực (Mạng LAN)'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuDivider(),
//                 const PopupMenuItem(
//                   value: 'web_demo',
//                   child: Row(
//                     children: [
//                       Icon(Icons.open_in_browser_rounded,
//                           color: Color(0xFF0284C7), size: 20),
//                       SizedBox(width: 10),
//                       Text('Mở Dashboard Web Demo'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'edit_image',
//                   child: Row(
//                     children: [
//                       Icon(Icons.edit_note_rounded,
//                           color: Color(0xFF0369A1), size: 20),
//                       SizedBox(width: 10),
//                       Text('Chỉnh Sửa Tiêu Đề / Ảnh Banner'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'update_firmware',
//                   child: Row(
//                     children: [
//                       Icon(Icons.system_update_rounded,
//                           color: Colors.orange, size: 20),
//                       SizedBox(width: 10),
//                       Text('Cập Nhật Firmware ESP32'),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
// 🟢 GIẢ ĐỊNH DÙNG CÁC SERVICE NHƯ BÊN MASTER SCREEN (Hãy đảm bảo đã import đúng file của dự án)
// import 'services/firmware_service.dart';
// import 'screens/web_ota_screen.dart';

class ConnectScreen extends StatefulWidget {
  final String? autoConnectIp;
  const ConnectScreen({super.key, this.autoConnectIp});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  // 🟢 KHAI BÁO BIẾN Ở ĐÂY (Mặc định là 'vi' - Tiếng Việt)
  String _selectedLang = 'vi';
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.0.27');
  bool _isLoading = false;

  // 🟢 State lưu Tiêu đề và Ảnh Banner màn hình Connect
  // String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
  // String _bgImagePath = 'assets/images/background.png';
  // 🟢 Getter tự động trả về tiêu đề theo ngôn ngữ đang chọn
String _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
String _bgImagePath = 'assets/images/background.png';

  // 🟢 State lưu đường dẫn file bin đã tải về điện thoại
  String? localDownloadedBinPath;
  bool _isOTAUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnectIp != null && widget.autoConnectIp!.isNotEmpty) {
      _ipController.text = widget.autoConnectIp!;
    }
    _loadSavedPreferences();
    _loadSavedLanguage();
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
  // 🟢 Đọc Tên App & Ảnh Banner đã lưu từ bộ nhớ máy
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
    final clean = input.trim();
    final ipRegExp = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegExp.hasMatch(clean) ||
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

  // 🟢 1. HÀM TẢI FIRMWARE .BIN VỀ ĐIỆN THOẠI (GIỐNG BÊN MASTER SCREEN)
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
    String version = '1.0.2';

    try {
      final configData = await _loadRemoteConfigFast();
      final firmwareInfo = configData['firmware_info'];
      if (firmwareInfo != null && firmwareInfo['bin_url'] != null) {
        binUrl = firmwareInfo['bin_url'].toString().trim();
        version = firmwareInfo['version'] ?? '1.0.2';
      }
    } catch (_) {}

    if (binUrl.isEmpty) {
      final releaseInfo = await fetchLatestRelease();
      if (releaseInfo != null) {
        binUrl = releaseInfo['download_url']!;
        version = releaseInfo['version']!;
      }
    }

    if (binUrl.isEmpty) {
      if (mounted) _showErrorSnackBar('Không tìm thấy link Firmware!');
      return;
    }

    if (!mounted) return;

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
                  Text('• Phiên bản: v$version', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isDownloading) ...[
                    LinearProgressIndicator(value: downloadProgress, color: const Color(0xFF0284C7)),
                    const SizedBox(height: 8),
                    Text('${(downloadProgress * 100).toInt()}% - Đang tải file .bin...'),
                  ] else ...[
                    const Text('File .bin sẽ được tải về lưu trữ tại thư mục Download/bin_esp32 của điện thoại.'),
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
                          downloadProgress = 0.3;
                        });
                      }
                      try {
                        // 🟢 Tải file .bin thông qua FirmwareService
                        final savedPath = await FirmwareService.downloadToBinFolder(binUrl, version: version);

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
                            content: Text('Đã tải v$version vào thư mục bin_esp32!'),
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

  // 🟢 2. HÀM CHUYỂN SANG MÀN HÌNH WEB OTA NẠP FILE BIN
  Future<void> _uploadLocalBinToESP32() async {
  final ip = _ipController.text.trim();
  // if (!_isValidServerAddress(ip)) {
  //   _showErrorSnackBar('Vui lòng nhập địa chỉ IP/Server hợp lệ!');
  //   return;
  // }
  if (!_isValidServerAddress(ip)) {
  _showErrorSnackBar(
    _selectedLang == 'vi'
        ? 'Vui lòng nhập địa chỉ IP/Server hợp lệ!'
        : 'Please enter a valid IP address or Server URL!',
  );
  return;
}

  setState(() {
    _isOTAUploading = true;
  });

  // 🟢 Mở trực tiếp màn hình WebOTAScreen ngay trong App
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebOTAScreen(ip: ip),
    ),
  );

  if (mounted) {
    setState(() {
      _isOTAUploading = false;
    });
    // Tự động kiểm tra lại kết nối sau khi người dùng nạp OTA xong và quay về
    _connect(); 
  }
}

  // 🟢 3. HÀM MỞ MÀN HÌNH WEB OTA TRÊN CHROME/TRÌNH DUYỆT NGOÀI
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

  void _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showErrorSnackBar('Vui lòng nhập địa chỉ IP hoặc Server Sa bàn!');
      return;
    }
    if (!_isValidServerAddress(ip)) {
      _showErrorSnackBar('Địa chỉ Server/IP không hợp lệ!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      Uri wsUrl;
      if (ip.contains('onrender.com') || ip.startsWith('wss://') || ip.startsWith('ws://')) {
        String formatted = ip;
        if (!formatted.startsWith('ws://') && !formatted.startsWith('wss://')) {
          formatted = 'wss://$formatted';
        }
        wsUrl = Uri.parse(formatted);
      } else {
        wsUrl = Uri.parse('ws://$ip:81');
      }
      final channel = WebSocketChannel.connect(wsUrl);
      final results = await Future.wait([
        channel.ready.timeout(
          const Duration(seconds: 4),
          onTimeout: () => throw TimeoutException('Mất kết nối'),
        ),
        _loadRemoteConfigFast(),
      ]);
      final configData = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MasterControlScreen(
            currentLang: _selectedLang, // 👈 Truyền giá trị ngôn ngữ sang màn hình điều khiển
            channel: channel,
            ip: ip,
            configData: configData,
            ledStates: const {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(
          'Không thể kết nối tới sa bàn ($ip). Vui lòng kiểm tra lại IP hoặc Wi-Fi!');
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

                        // if (mounted) {
                        //   setState(() {
                        //     _appTitle = 'ĐIỀU KHIỂN SA BÀN THÔNG MINH';
                        //     _bgImagePath = 'assets/images/background.png';
                        //   });
                        // }
                        if (mounted) {
  setState(() {
    // 🟢 Không gán _appTitle ở đây nữa để Getter tự động làm việc theo _selectedLang
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
                            // labelText: 'Địa chỉ IP / Server Sa bàn',
                            labelText: _selectedLang == 'vi'
    ? 'Địa chỉ IP / Server Sa bàn'
    : 'IP Address / Model Server',
                            labelStyle: const TextStyle(
                                color: Color(0xFF0369A1), fontSize: 13),
                            // hintText:
                            //     'VD: 192.168.0.27 hoặc saban-demo.onrender.com',
                            hintText: _selectedLang == 'vi'
        ? 'Ví dụ: 192.168.0.27 hoặc saban-demo.onrender.com'
        : 'e.g., 192.168.0.27 or saban-demo.onrender.com',
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
                        // SizedBox(
                        //   width: double.infinity,
                        //   height: 48,
                        //   child: InkWell(
                        //     onTap: _isLoading ? null : _connect,
                        //     borderRadius: BorderRadius.circular(12),
                        //     child: AnimatedContainer(
                        //       duration: const Duration(milliseconds: 200),
                        //       decoration: BoxDecoration(
                        //         gradient: _isLoading
                        //             ? const LinearGradient(colors: [
                        //                 Color(0xFF94A3B8),
                        //                 Color(0xFF64748B)
                        //               ])
                        //             : const LinearGradient(
                        //                 colors: [
                        //                   Color(0xFF0284C7),
                        //                   Color(0xFF0369A1)
                        //                 ],
                        //                 begin: Alignment.topLeft,
                        //                 end: Alignment.bottomRight,
                        //               ),
                        //         borderRadius: BorderRadius.circular(12),
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: const Color(0xFF0284C7)
                        //                 .withValues(alpha: 0.3),
                        //             blurRadius: 12,
                        //             offset: const Offset(0, 4),
                        //           ),
                        //         ],
                        //       ),
                        //       child: Center(
                        //         child: _isLoading
                        //             ? const Row(
                        //                 mainAxisAlignment:
                        //                     MainAxisAlignment.center,
                        //                 children: [
                        //                   SizedBox(
                        //                     width: 18,
                        //                     height: 18,
                        //                     child: CircularProgressIndicator(
                        //                       color: Colors.white,
                        //                       strokeWidth: 2,
                        //                     ),
                        //                   ),
                        //                   SizedBox(width: 10),
                        //                   Text(
                        //                     'Đang kết nối, vui lòng chờ chút ạ!',
                        //                     style: TextStyle(
                        //                       color: Colors.white,
                        //                       fontWeight: FontWeight.bold,
                        //                       fontSize: 14,
                        //                     ),
                        //                   ),
                        //                 ],
                        //               )
                        //             : const Row(
                        //                 mainAxisAlignment:
                        //                     MainAxisAlignment.center,
                        //                 children: [
                        //                   Icon(
                        //                       Icons.power_settings_new_rounded,
                        //                       color: Colors.white,
                        //                       size: 18),
                        //                   SizedBox(width: 8),
                        //                   Text(
                        //                     'KẾT NỐI VÀ TẢI SA BÀN',
                        //                     style: TextStyle(
                        //                       color: Colors.white,
                        //                       fontSize: 14,
                        //                       fontWeight: FontWeight.bold,
                        //                       letterSpacing: 0.8,
                        //                     ),
                        //                   ),
                        //                 ],
                        //               ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
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

//   Widget _buildTopBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withValues(alpha: 0.9),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: PopupMenuButton<String>(
//               icon: const Icon(Icons.menu_rounded,
//                   color: Color(0xFF0369A1), size: 22),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16)),
//               onSelected: (value) {
//                 if (value == 'demo_mode') {
//                   setState(() {
//                     _ipController.text = 'saban-demo.onrender.com';
//                   });
//                   _connect();
//                 } else if (value == 'real_mode') {
//                   setState(() {
//                     _ipController.text = '192.168.0.27';
//                   });
//                   _connect();
//                 } else if (value == 'web_demo') {
//                   _openWebDashboard();
//                 } else if (value == 'edit_image') {
//                   _showImageEditDialog(context);
//                 } else if (value == 'download_firmware') {
//                   _downloadFirmwareToPhone(); // 🟢 Tải file bin về điện thoại
//                 } else if (value == 'upload_ota') {
//                   _uploadLocalBinToESP32(); // 🟢 Nạp Web OTA trong app
//                 } else if (value == 'open_chrome_ota') {
//                   openWebOTAInChrome(_ipController.text.trim()); // 🟢 Mở Web OTA trình duyệt ngoài
//                 }
//               },
//               itemBuilder: (BuildContext context) => [
//   const PopupMenuItem(
//     value: 'demo_mode',
//     child: Row(
//       children: [
//         Icon(Icons.cloud_done_rounded, color: Color(0xFF0284C7), size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             'Dùng Sa Bàn Demo Cloud',
//             style: TextStyle(fontWeight: FontWeight.bold),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuItem(
//     value: 'real_mode',
//     child: Row(
//       children: [
//         Icon(Icons.lan_rounded, color: Colors.green, size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             'Dùng Sa Bàn Thực (Mạng LAN)',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuDivider(),
//   const PopupMenuItem(
//     value: 'web_demo',
//     child: Row(
//       children: [
//         Icon(Icons.open_in_browser_rounded, color: Color(0xFF0284C7), size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             'Mở Dashboard Web Demo',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuItem(
//     value: 'edit_image',
//     child: Row(
//       children: [
//         Icon(Icons.edit_note_rounded, color: Color(0xFF0369A1), size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             'Chỉnh Sửa Tiêu Đề / Ảnh Banner',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuDivider(),
//   const PopupMenuItem(
//     value: 'download_firmware',
//     child: Row(
//       children: [
//         Icon(Icons.download_for_offline_rounded, color: Color(0xFF0284C7), size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             '1. Tải Firmware .bin về điện thoại',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuItem(
//     value: 'upload_ota',
//     child: Row(
//       children: [
//         Icon(Icons.system_update_rounded, color: Colors.orange, size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             '2. Nạp file .bin vào ESP32 (Web OTA)',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
//   const PopupMenuItem(
//     value: 'open_chrome_ota',
//     child: Row(
//       children: [
//         Icon(Icons.chrome_reader_mode_rounded, color: Colors.green, size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             'Mở Trang Nạp OTA Trên Trình Duyệt',
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   ),
// ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// Widget _buildTopBar(BuildContext context) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // 1. Nút Menu bên trái
//         Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white.withValues(alpha: 0.9),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//                 blurRadius: 10,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: PopupMenuButton<String>(
//             constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
//             icon: const Icon(Icons.menu_rounded,
//                 color: Color(0xFF0369A1), size: 22),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16)),
//             onSelected: (value) {
//               if (value == 'demo_mode') {
//                 setState(() {
//                   _ipController.text = 'saban-demo.onrender.com';
//                 });
//                 _connect();
//               } else if (value == 'real_mode') {
//                 setState(() {
//                   _ipController.text = '192.168.0.27';
//                 });
//                 _connect();
//               } else if (value == 'web_demo') {
//                 _openWebDashboard();
//               } else if (value == 'edit_image') {
//                 _showImageEditDialog(context);
//               } else if (value == 'download_firmware') {
//                 _downloadFirmwareToPhone();
//               } else if (value == 'upload_ota') {
//                 _uploadLocalBinToESP32();
//               } else if (value == 'open_chrome_ota') {
//                 openWebOTAInChrome(_ipController.text.trim());
//               }
//             },
//             itemBuilder: (BuildContext context) => [
//               const PopupMenuItem(
//                 value: 'demo_mode',
//                 child: Row(
//                   children: [
//                     Icon(Icons.cloud_done_rounded,
//                         color: Color(0xFF0284C7), size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('Dùng Sa Bàn Demo Cloud',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'real_mode',
//                 child: Row(
//                   children: [
//                     Icon(Icons.lan_rounded, color: Colors.green, size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('Dùng Sa Bàn Thực (Mạng LAN)',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuDivider(),
//               const PopupMenuItem(
//                 value: 'web_demo',
//                 child: Row(
//                   children: [
//                     Icon(Icons.open_in_browser_rounded,
//                         color: Color(0xFF0284C7), size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('Mở Dashboard Web Demo',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'edit_image',
//                 child: Row(
//                   children: [
//                     Icon(Icons.edit_note_rounded,
//                         color: Color(0xFF0369A1), size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('Chỉnh Sửa Tiêu Đề / Ảnh Banner',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuDivider(),
//               const PopupMenuItem(
//                 value: 'download_firmware',
//                 child: Row(
//                   children: [
//                     Icon(Icons.download_for_offline_rounded,
//                         color: Color(0xFF0284C7), size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('1. Tải Firmware .bin về điện thoại',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'upload_ota',
//                 child: Row(
//                   children: [
//                     Icon(Icons.system_update_rounded,
//                         color: Colors.orange, size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('2. Nạp file .bin vào ESP32 (Web OTA)',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'open_chrome_ota',
//                 child: Row(
//                   children: [
//                     Icon(Icons.chrome_reader_mode_rounded,
//                         color: Colors.green, size: 20),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Text('Mở Trang Nạp OTA Trên Trình Duyệt',
//                           overflow: TextOverflow.ellipsis),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // 🟢 2. Nút Icon Information bên phải
//         // Container(
//         //   decoration: BoxDecoration(
//         //     shape: BoxShape.circle,
//         //     color: Colors.white.withValues(alpha: 0.9),
//         //     boxShadow: [
//         //       BoxShadow(
//         //         color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//         //         blurRadius: 10,
//         //         offset: const Offset(0, 3),
//         //       ),
//         //     ],
//         //   ),
//         //   child: IconButton(
//         //     icon: const Icon(Icons.info_outline_rounded,
//         //         color: Color(0xFF0369A1), size: 22),
//         //     onPressed: () {
//         //       showAboutDialog(
//         //         context: context,
//         //         applicationName: _appTitle,
//         //         applicationVersion: 'v1.0.2',
//         //         applicationIcon: const Icon(Icons.domain_rounded,
//         //             color: Color(0xFF0284C7), size: 36),
//         //         children: const [
//         //           Text(
//         //               'Ứng dụng điều khiển sa bàn thông minh kết nối qua mạng LAN/Cloud.'),
//         //         ],
//         //       );
//         //     },
//         //   ),
//         // ),
//         Row(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     // 🟢 1. Nút chuyển đổi Ngôn Ngữ VN / EN
//     GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedLang = (_selectedLang == 'vi') ? 'en' : 'vi';
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.white.withValues(alpha: 0.9),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//               blurRadius: 10,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _selectedLang == 'vi' ? '🇻🇳 VN' : '🇬🇧 EN',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: Color(0xFF0369A1),
//               ),
//             ),
//             const SizedBox(width: 4),
//             const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF0369A1)),
//           ],
//         ),
//       ),
//     ),

//     const SizedBox(width: 8), // Khoảng cách giữa 2 nút

//     // 🟢 2. Nút Thông tin (Gốc của bạn)
//     Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.white.withValues(alpha: 0.9),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF0284C7).withValues(alpha: 0.12),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: IconButton(
//         icon: const Icon(Icons.info_outline_rounded,
//             color: Color(0xFF0369A1), size: 22),
//         onPressed: () {
//           showAboutDialog(
//             context: context,
//             applicationName: _appTitle,
//             applicationVersion: 'v1.0.2',
//             applicationIcon: const Icon(Icons.domain_rounded,
//                 color: Color(0xFF0284C7), size: 36),
//             children: [
//               Text(_selectedLang == 'vi' 
//                 ? 'Ứng dụng điều khiển sa bàn thông minh kết nối qua mạng LAN/Cloud.'
//                 : 'Smart scale model control application via LAN/Cloud connection.'),
//             ],
//           );
//         },
//       ),
//     ),
//   ],
// )
//       ],
//     ),
//   );
// }

Widget _buildTopBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Nút Menu bên trái
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
                  _ipController.text = '192.168.0.27';
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

        // 2. Cụm nút bên phải: Chuyển ngôn ngữ & Thông tin
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // // 🟢 Nút chuyển đổi Ngôn Ngữ VN / EN
            // GestureDetector(
            //   onTap: () {
            //     setState(() {
            //       _selectedLang = (_selectedLang == 'vi') ? 'en' : 'vi';
            //     });
            //   },
            //   child: Container(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withValues(alpha: 0.9),
            //       borderRadius: BorderRadius.circular(20),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            //           blurRadius: 10,
            //           offset: const Offset(0, 3),
            //         ),
            //       ],
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Text(
            //           _selectedLang == 'vi' ? '🇻🇳 VN' : '🇬🇧 EN',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 13,
            //             color: Color(0xFF0369A1),
            //           ),
            //         ),
            //         const SizedBox(width: 4),
            //         const Icon(
            //           Icons.swap_horiz_rounded,
            //           size: 16,
            //           color: Color(0xFF0369A1),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // 🟢 THIẾT KẾ THANH GẠT CHUYỂN NGÔN NGỮ (VN ↔ EN)
// 🟢 CODE THANH GẠT CHUẨN CÂN ĐỐI (KHÔNG BỊ CHE CHỮ)
// 🟢 THANH GẠT PHONG CÁCH SEGMENTED CONTROL (CỰC KỲ ĐẸP & RÕ RÀNG)
GestureDetector(
  // onTap: () {
  //   setState(() {
  //     _selectedLang = (_selectedLang == 'vi') ? 'en' : 'vi';
  //     _appTitle = _selectedLang == 'vi'
  //         ? 'ĐIỀU KHIỂN SA BÀN THÔNG MINH'
  //         : 'SMART SCALE MODEL CONTROLLER';
  //   });
  //   debugPrint("🌐 Switched Language to: $_selectedLang");
  // },
  onTap: () async {
  final newLang = (_selectedLang == 'vi') ? 'en' : 'vi';
  
  setState(() {
    _selectedLang = newLang;
    _appTitle = _selectedLang == 'vi'
        ? 'ĐIỀU KHIỂN SA BÀN THÔNG MINH'
        : 'SMART SCALE MODEL CONTROLLER';
  });

  // 🟢 Lưu lại ngôn ngữ vừa chọn vào bộ nhớ thiết bị
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
        // 1. Lớp chữ ẩn nằm bên dưới (Dành cho trạng thái không chọn)
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

        // 2. Cục trượt màu trắng nổi hẳn lên chứa Cờ + Chữ của Ngôn ngữ đang chọn
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

            // 🟢 Nút Thông tin app
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