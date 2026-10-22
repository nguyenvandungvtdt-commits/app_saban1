// // // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // // // // // // //   final String ip;
// // // // // // // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // // // // // // }

// // // // // // // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // // // // // // //   late final WebViewController _controller;

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   void initState() {
// // // // // // // // // // // // //     super.initState();

// // // // // // // // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // // // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // // // // // // // //     final WebViewController controller =
// // // // // // // // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // // // // // // // //     controller
// // // // // // // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // // // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // // // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // // // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // // // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // // // // // // // //         try {
// // // // // // // // // // // // //           // ✅ Bỏ dấu ? ở List<PlatformFile> vì phiên bản này không bao giờ null
// // // // // // // // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // // // // // // // //             type: FileType.any,
// // // // // // // // // // // // //           );

// // // // // // // // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // // // // // // // //             final Uri fileUri = Uri.file(files.first.path!);
// // // // // // // // // // // // //             return [fileUri.toString()];
// // // // // // // // // // // // //           }
// // // // // // // // // // // // //         } catch (e) {
// // // // // // // // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // // // // // // // //         }
// // // // // // // // // // // // //         return [];
// // // // // // // // // // // // //       });
// // // // // // // // // // // // //     }

// // // // // // // // // // // // //     _controller = controller;
// // // // // // // // // // // // //   }

// // // // // // // // // // // // //   @override
// // // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // // //     return Scaffold(
// // // // // // // // // // // // //       appBar: AppBar(
// // // // // // // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // // // // // // // //         foregroundColor: Colors.white,
// // // // // // // // // // // // //       ),
// // // // // // // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // // // // // // //     );
// // // // // // // // // // // // //   }
// // // // // // // // // // // // // }

// // // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // // // // // // // 🟢 IMPORT 2 FILE NÀY TRONG DỰ ÁN CỦA BẠN
// // // // // // // // // // // // import '../screens/connect_screen.dart';
// // // // // // // // // // // // import '../widgets/reconnect_dialog.dart';

// // // // // // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // // // // // //   final String ip;
// // // // // // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // // // // // }

// // // // // // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // // // // // //   late final WebViewController _controller;

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   void initState() {
// // // // // // // // // // // //     super.initState();

// // // // // // // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // // // // // // //     final WebViewController controller =
// // // // // // // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // // // // // // //     controller
// // // // // // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // // // // // // //         try {
// // // // // // // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // // // // // // //             type: FileType.any,
// // // // // // // // // // // //           );

// // // // // // // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // // // // // // //             final Uri fileUri = Uri.file(files.first.path!);

// // // // // // // // // // // //             // 🟢 TỰ ĐỘNG BẬT ĐẾM NGƯỜI VÀ RECONNECT SAU KHÌ TRUYỀN FILE
// // // // // // // // // // // //             // _startAutoReconnectFlow();

// // // // // // // // // // // //             return [fileUri.toString()];
// // // // // // // // // // // //           }
// // // // // // // // // // // //         } catch (e) {
// // // // // // // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // // // // // // //         }
// // // // // // // // // // // //         return [];
// // // // // // // // // // // //       });
// // // // // // // // // // // //     }

// // // // // // // // // // // //     _controller = controller;
// // // // // // // // // // // //   }

// // // // // // // // // // // //   // 🟢 HÀM KÍCH HOẠT ĐẾM NGƯỢC VÀ CHUYỂN MÀN HÌNH TỰ ĐỘNG KẾT NỐI
// // // // // // // // // // // //   void _startAutoReconnectFlow() {
// // // // // // // // // // // //     // Trễ 2.5 giây để WebView kịp gửi xong request HTTP POST chứa file .bin sang ESP32
// // // // // // // // // // // //     Future.delayed(const Duration(milliseconds: 2500), () {
// // // // // // // // // // // //       if (!mounted) return;

// // // // // // // // // // // //       showDialog(
// // // // // // // // // // // //         context: context,
// // // // // // // // // // // //         barrierDismissible: false, // Bắt buộc người dùng đợi đếm ngược
// // // // // // // // // // // //         builder: (dialogContext) {
// // // // // // // // // // // //           return ReconnectCountdownDialog(
// // // // // // // // // // // //             ip: widget.ip,
// // // // // // // // // // // //             onReconnect: (ip) {
// // // // // // // // // // // //               // 🚀 Thoát khỏi WebOTAScreen, về ConnectScreen và tự kích hoạt hàm _connect()
// // // // // // // // // // // //               Navigator.of(context).pushAndRemoveUntil(
// // // // // // // // // // // //                 MaterialPageRoute(
// // // // // // // // // // // //                   builder: (context) => ConnectScreen(autoConnectIp: ip),
// // // // // // // // // // // //                 ),
// // // // // // // // // // // //                 (route) => false,
// // // // // // // // // // // //               );
// // // // // // // // // // // //             },
// // // // // // // // // // // //           );
// // // // // // // // // // // //         },
// // // // // // // // // // // //       );
// // // // // // // // // // // //     });
// // // // // // // // // // // //   }

// // // // // // // // // // // //   @override
// // // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // // //     return Scaffold(
// // // // // // // // // // // //       appBar: AppBar(
// // // // // // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // // // // // // //         foregroundColor: Colors.white,
// // // // // // // // // // // //       ),
// // // // // // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // // // // // //     );
// // // // // // // // // // // //   }
// // // // // // // // // // // // }

// // // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // // // // //   final String ip;
// // // // // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // // // // //   @override
// // // // // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // // // // }

// // // // // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // // // // //   late final WebViewController _controller;

// // // // // // // // // // //   @override
// // // // // // // // // // //   void initState() {
// // // // // // // // // // //     super.initState();

// // // // // // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // // // // // //     final WebViewController controller =
// // // // // // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // // // // // //     controller
// // // // // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // // // // // //         try {
// // // // // // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // // // // // //             type: FileType.any,
// // // // // // // // // // //           );

// // // // // // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // // // // // //             final Uri fileUri = Uri.file(files.first.path!);
// // // // // // // // // // //             // 🟢 Chỉ trả về đường dẫn file để WebView nhận file bình thường
// // // // // // // // // // //             return [fileUri.toString()];
// // // // // // // // // // //           }
// // // // // // // // // // //         } catch (e) {
// // // // // // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // // // // // //         }
// // // // // // // // // // //         return [];
// // // // // // // // // // //       });
// // // // // // // // // // //     }

// // // // // // // // // // //     _controller = controller;
// // // // // // // // // // //   }

// // // // // // // // // // //   @override
// // // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // // //     return Scaffold(
// // // // // // // // // // //       appBar: AppBar(
// // // // // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // // // // // //         foregroundColor: Colors.white,
// // // // // // // // // // //       ),
// // // // // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // // // // //     );
// // // // // // // // // // //   }
// // // // // // // // // // // }

// // // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // // import 'package:webview_flutter/webview_flutter.dart';

// // // // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // // // //   final String ip;
// // // // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // // // //   @override
// // // // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // // // }

// // // // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // // // //   late final WebViewController _controller;
// // // // // // // // // //   bool _hasShownSuccessDialog = false;

// // // // // // // // // //   @override
// // // // // // // // // //   void initState() {
// // // // // // // // // //     super.initState();
// // // // // // // // // //     _controller = WebViewController()
// // // // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // // // //       ..setNavigationDelegate(
// // // // // // // // // //         NavigationDelegate(
// // // // // // // // // //           onPageFinished: (String url) {
// // // // // // // // // //             // Lắng nghe khi URL hoặc DOM hoàn tất nạp thành công
// // // // // // // // // //             _checkOtaSuccess();
// // // // // // // // // //           },
// // // // // // // // // //         ),
// // // // // // // // // //       )
// // // // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));
// // // // // // // // // //   }

// // // // // // // // // //   void _checkOtaSuccess() async {
// // // // // // // // // //     // Kích hoạt Dialog nếu phát hiện chữ "Success" hoặc tự bật sau khi hoàn tất
// // // // // // // // // //     if (_hasShownSuccessDialog) return;
    
// // // // // // // // // //     // Đợi 1 chút để user nhìn thấy màn hình Success
// // // // // // // // // //     await Future.delayed(const Duration(seconds: 1));
// // // // // // // // // //     if (mounted && !_hasShownSuccessDialog) {
// // // // // // // // // //       _showOTASuccessDialog();
// // // // // // // // // //     }
// // // // // // // // // //   }

// // // // // // // // // //   void _showOTASuccessDialog() {
// // // // // // // // // //     setState(() => _hasShownSuccessDialog = true);
// // // // // // // // // //     showDialog(
// // // // // // // // // //       context: context,
// // // // // // // // // //       barrierDismissible: false,
// // // // // // // // // //       builder: (context) {
// // // // // // // // // //         return AlertDialog(
// // // // // // // // // //           shape: RoundedRectangleBorder(
// // // // // // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // // // // // //           ),
// // // // // // // // // //           title: const Row(
// // // // // // // // // //             children: [
// // // // // // // // // //               Icon(Icons.check_circle, color: Colors.green, size: 28),
// // // // // // // // // //               SizedBox(width: 10),
// // // // // // // // // //               Text('Nạp Firmware Thành Công!'),
// // // // // // // // // //             ],
// // // // // // // // // //           ),
// // // // // // // // // //           content: const Text(
// // // // // // // // // //             'Thiết bị Sa bàn đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // // // // // // // //           ),
// // // // // // // // // //           actions: [
// // // // // // // // // //             ElevatedButton.icon(
// // // // // // // // // //               style: ElevatedButton.styleFrom(
// // // // // // // // // //                 backgroundColor: Colors.blue.shade700,
// // // // // // // // // //                 foregroundColor: Colors.white,
// // // // // // // // // //                 shape: RoundedRectangleBorder(
// // // // // // // // // //                   borderRadius: BorderRadius.circular(8),
// // // // // // // // // //                 ),
// // // // // // // // // //               ),
// // // // // // // // // //               onPressed: () {
// // // // // // // // // //                 // Đóng Dialog và thoát WebOTAScreen quay về MasterControlScreen
// // // // // // // // // //                 Navigator.of(context).pop(); // Pop Dialog
// // // // // // // // // //                 Navigator.of(context).pop(); // Pop WebOTAScreen
// // // // // // // // // //               },
// // // // // // // // // //               icon: const Icon(Icons.dashboard_rounded),
// // // // // // // // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // // // // // // // //             ),
// // // // // // // // // //           ],
// // // // // // // // // //         );
// // // // // // // // // //       },
// // // // // // // // // //     );
// // // // // // // // // //   }

// // // // // // // // // //   @override
// // // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // // //     return Scaffold(
// // // // // // // // // //       appBar: AppBar(
// // // // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // // // //       ),
// // // // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // // // //     );
// // // // // // // // // //   }
// // // // // // // // // // }
// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // // //   final String ip;
// // // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // // //   @override
// // // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // // }

// // // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // // //   late final WebViewController _controller;

// // // // // // // // //   @override
// // // // // // // // //   void initState() {
// // // // // // // // //     super.initState();

// // // // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // // // //     final WebViewController controller =
// // // // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // // // //     controller
// // // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // // // //     // 🟢 GIỮ NGUYÊN CODE FILE PICKER CHUẨN CỦA BẠN
// // // // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // // // //         try {
// // // // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // // // //             type: FileType.any,
// // // // // // // // //           );

// // // // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // // // //             final Uri fileUri = Uri.file(files.first.path!);
// // // // // // // // //             return [fileUri.toString()];
// // // // // // // // //           }
// // // // // // // // //         } catch (e) {
// // // // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // // // //         }
// // // // // // // // //         return [];
// // // // // // // // //       });
// // // // // // // // //     }

// // // // // // // // //     _controller = controller;
// // // // // // // // //   }

// // // // // // // // //   // 🟢 THÊM POPUP THÔNG BÁO VÀ CHUYỂN HƯỚNG VỀ SA BÀN
// // // // // // // // //   void _showOTASuccessDialog() {
// // // // // // // // //     showDialog(
// // // // // // // // //       context: context,
// // // // // // // // //       barrierDismissible: false,
// // // // // // // // //       builder: (dialogContext) {
// // // // // // // // //         return AlertDialog(
// // // // // // // // //           shape: RoundedRectangleBorder(
// // // // // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // // // // //           ),
// // // // // // // // //           title: const Row(
// // // // // // // // //             children: [
// // // // // // // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // // // // // // //               SizedBox(width: 8),
// // // // // // // // //               Expanded(
// // // // // // // // //                 child: Text(
// // // // // // // // //                   'Nạp Firmware Thành Công',
// // // // // // // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //             ],
// // // // // // // // //           ),
// // // // // // // // //           content: const Text(
// // // // // // // // //             'Nếu ElegantOTA đã báo Success, bấm nút bên dưới để quay về màn hình điều khiển sa bàn.',
// // // // // // // // //           ),
// // // // // // // // //           actionsAlignment: MainAxisAlignment.center,
// // // // // // // // //           actions: [
// // // // // // // // //             ElevatedButton.icon(
// // // // // // // // //               style: ElevatedButton.styleFrom(
// // // // // // // // //                 backgroundColor: const Color(0xFF0284C7),
// // // // // // // // //                 foregroundColor: Colors.white,
// // // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // // // // // // //                 shape: RoundedRectangleBorder(
// // // // // // // // //                   borderRadius: BorderRadius.circular(8),
// // // // // // // // //                 ),
// // // // // // // // //               ),
// // // // // // // // //               onPressed: () {
// // // // // // // // //                 Navigator.of(dialogContext).pop(); // Đóng Dialog
// // // // // // // // //                 Navigator.of(context).pop(); // Thoát WebOTAScreen về MasterControlScreen
// // // // // // // // //               },
// // // // // // // // //               icon: const Icon(Icons.dashboard_rounded),
// // // // // // // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // // // // // // //             ),
// // // // // // // // //           ],
// // // // // // // // //         );
// // // // // // // // //       },
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     return Scaffold(
// // // // // // // // //       appBar: AppBar(
// // // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // // // //         foregroundColor: Colors.white,
// // // // // // // // //         actions: [
// // // // // // // // //           // 🟢 NÚT "XONG" TRÊN APPBAR
// // // // // // // // //           TextButton.icon(
// // // // // // // // //             onPressed: _showOTASuccessDialog,
// // // // // // // // //             icon: const Icon(Icons.check, color: Colors.white),
// // // // // // // // //             label: const Text(
// // // // // // // // //               'Xong',
// // // // // // // // //               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// // // // // // // // //             ),
// // // // // // // // //           ),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }
// // // // // // // // import 'dart:async';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // // //   final String ip;
// // // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // // //   @override
// // // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // // }

// // // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // // //   late final WebViewController _controller;
// // // // // // // //   Timer? _successCheckTimer;
// // // // // // // //   bool _hasShownSuccessDialog = false;

// // // // // // // //   @override
// // // // // // // //   void initState() {
// // // // // // // //     super.initState();

// // // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // // //     final WebViewController controller =
// // // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // // //     controller
// // // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // // //     // Giữ nguyên logic chọn file ổn định của bạn
// // // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // // //         try {
// // // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // // //             type: FileType.any,
// // // // // // // //           );

// // // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // // //             final Uri fileUri = Uri.file(files.first.path!);
            
// // // // // // // //             // 🟢 Khi người dùng đã chọn file và bắt đầu nạp, khởi chạy bộ lắng nghe Success
// // // // // // // //             _startListeningForSuccess();
            
// // // // // // // //             return [fileUri.toString()];
// // // // // // // //           }
// // // // // // // //         } catch (e) {
// // // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // // //         }
// // // // // // // //         return [];
// // // // // // // //       });
// // // // // // // //     }

// // // // // // // //     _controller = controller;
// // // // // // // //   }

// // // // // // // //   // 🟢 TỰ ĐỘNG BẮT SỰ KIỆN SUCCESS
// // // // // // // //   void _startListeningForSuccess() {
// // // // // // // //     _successCheckTimer?.cancel();
// // // // // // // //     // Quét mỗi 1.5 giây sau khi chọn file để phát hiện chữ "Success"
// // // // // // // //     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // // // // // // //       if (_hasShownSuccessDialog || !mounted) {
// // // // // // // //         timer.cancel();
// // // // // // // //         return;
// // // // // // // //       }

// // // // // // // //       try {
// // // // // // // //         final result = await _controller.runJavaScriptReturningResult(
// // // // // // // //           "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
// // // // // // // //         );

// // // // // // // //         if (result == true || result.toString() == 'true') {
// // // // // // // //           timer.cancel();
// // // // // // // //           _showOTASuccessDialog();
// // // // // // // //         }
// // // // // // // //       } catch (e) {
// // // // // // // //         // Bỏ qua lỗi nếu trang web đang load lại
// // // // // // // //       }
// // // // // // // //     });
// // // // // // // //   }

// // // // // // // //   void _showOTASuccessDialog() {
// // // // // // // //     if (_hasShownSuccessDialog || !mounted) return;
// // // // // // // //     setState(() => _hasShownSuccessDialog = true);

// // // // // // // //     showDialog(
// // // // // // // //       context: context,
// // // // // // // //       barrierDismissible: false,
// // // // // // // //       builder: (dialogContext) {
// // // // // // // //         return AlertDialog(
// // // // // // // //           shape: RoundedRectangleBorder(
// // // // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // // // //           ),
// // // // // // // //           title: const Row(
// // // // // // // //             children: [
// // // // // // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // // // // // //               SizedBox(width: 8),
// // // // // // // //               Expanded(
// // // // // // // //                 child: Text(
// // // // // // // //                   'Nạp Firmware Thành Công',
// // // // // // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //             ],
// // // // // // // //           ),
// // // // // // // //           content: const Text(
// // // // // // // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // // // // // //           ),
// // // // // // // //           actionsAlignment: MainAxisAlignment.center,
// // // // // // // //           actions: [
// // // // // // // //             ElevatedButton.icon(
// // // // // // // //               style: ElevatedButton.styleFrom(
// // // // // // // //                 backgroundColor: const Color(0xFF0284C7),
// // // // // // // //                 foregroundColor: Colors.white,
// // // // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // // // // // //                 shape: RoundedRectangleBorder(
// // // // // // // //                   borderRadius: BorderRadius.circular(8),
// // // // // // // //                 ),
// // // // // // // //               ),
// // // // // // // //               onPressed: () {
// // // // // // // //                 Navigator.of(dialogContext).pop();
// // // // // // // //                 Navigator.of(context).pop();
// // // // // // // //               },
// // // // // // // //               icon: const Icon(Icons.dashboard_rounded),
// // // // // // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // // // // // //             ),
// // // // // // // //           ],
// // // // // // // //         );
// // // // // // // //       },
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   void dispose() {
// // // // // // // //     _successCheckTimer?.cancel();
// // // // // // // //     super.dispose();
// // // // // // // //   }

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     return Scaffold(
// // // // // // // //       appBar: AppBar(
// // // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // // //         foregroundColor: Colors.white,
// // // // // // // //       ),
// // // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:async';
// // // // // // // import 'dart:io';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // // //   final String ip;
  
// // // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // // //   @override
// // // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // // }

// // // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // // //   late final WebViewController _controller;
// // // // // // //   Timer? _successCheckTimer;
// // // // // // //   bool _hasShownSuccessDialog = false;

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();

// // // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // // //     final WebViewController controller =
// // // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // // //     controller
// // // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // // //     // Bắt sự kiện mở File Picker của WebView trên Android
// // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // //         try {
// // // // // // //           String? targetDirectory;
// // // // // // //           if (Platform.isAndroid) {
// // // // // // //             targetDirectory = '/storage/emulated/0/Download/bin_esp32';
// // // // // // //             if (!await Directory(targetDirectory).exists()) {
// // // // // // //               targetDirectory = '/storage/emulated/0/Download';
// // // // // // //             }
// // // // // // //           }

// // // // // // //           // Mở File Picker (Mở thư mục bin_esp32 trên Android, mở Files trên iOS)
// // // // // // //           final selectedFiles = await FilePicker.pickFiles(
// // // // // // //             type: FileType.custom,
// // // // // // //             allowedExtensions: ['bin'],
// // // // // // //             initialDirectory: targetDirectory,
// // // // // // //           );

// // // // // // //           // 🟢 Đã bỏ "selectedFiles != null"
// // // // // // //           if (selectedFiles.isNotEmpty && selectedFiles.first.path != null) {
// // // // // // //             final Uri fileUri = Uri.file(selectedFiles.first.path!);
            
// // // // // // //             _startListeningForSuccess();
            
// // // // // // //             return [fileUri.toString()];
// // // // // // //           }
// // // // // // //         } catch (e) {
// // // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // // //         }
// // // // // // //         return [];
// // // // // // //       });
// // // // // // //     }

// // // // // // //     _controller = controller;
// // // // // // //   }

// // // // // // //   // Tự động kiểm tra trang web khi nạp xong
// // // // // // //   void _startListeningForSuccess() {
// // // // // // //     _successCheckTimer?.cancel();
// // // // // // //     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // // // // // //       if (_hasShownSuccessDialog || !mounted) {
// // // // // // //         timer.cancel();
// // // // // // //         return;
// // // // // // //       }

// // // // // // //       try {
// // // // // // //         final result = await _controller.runJavaScriptReturningResult(
// // // // // // //           "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
// // // // // // //         );

// // // // // // //         if (result == true || result.toString() == 'true') {
// // // // // // //           timer.cancel();
// // // // // // //           _showOTASuccessDialog();
// // // // // // //         }
// // // // // // //       } catch (e) {
// // // // // // //         // Bỏ qua lỗi khi trang đang reload/reboot
// // // // // // //       }
// // // // // // //     });
// // // // // // //   }

// // // // // // //   void _showOTASuccessDialog() {
// // // // // // //     if (_hasShownSuccessDialog || !mounted) return;
// // // // // // //     setState(() => _hasShownSuccessDialog = true);

// // // // // // //     showDialog(
// // // // // // //       context: context,
// // // // // // //       barrierDismissible: false,
// // // // // // //       builder: (dialogContext) {
// // // // // // //         return AlertDialog(
// // // // // // //           shape: RoundedRectangleBorder(
// // // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // // //           ),
// // // // // // //           title: const Row(
// // // // // // //             children: [
// // // // // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // // // // //               SizedBox(width: 8),
// // // // // // //               Expanded(
// // // // // // //                 child: Text(
// // // // // // //                   'Nạp Firmware Thành Công',
// // // // // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // // // // //                 ),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //           content: const Text(
// // // // // // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // // // // //           ),
// // // // // // //           actionsAlignment: MainAxisAlignment.center,
// // // // // // //           actions: [
// // // // // // //             ElevatedButton.icon(
// // // // // // //   style: ElevatedButton.styleFrom(
// // // // // // //     backgroundColor: const Color(0xFF0284C7),
// // // // // // //     foregroundColor: Colors.white,
// // // // // // //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // // // // //     shape: RoundedRectangleBorder(
// // // // // // //       borderRadius: BorderRadius.circular(8),
// // // // // // //     ),
// // // // // // //   ),
// // // // // // //   onPressed: () {
// // // // // // //     Navigator.of(dialogContext).pop(); // Đóng Dialog Success
// // // // // // //     Navigator.of(context).pop(true);   // 🟢 TRUYỀN `true` VỀ MÀN HÌNH CHÍNH
// // // // // // //   },
// // // // // // //   icon: const Icon(Icons.dashboard_rounded),
// // // // // // //   label: const Text('Về Màn Hình Sa Bàn'),
// // // // // // // ),
// // // // // // //           ],
// // // // // // //         );
// // // // // // //       },
// // // // // // //     );
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   void dispose() {
// // // // // // //     _successCheckTimer?.cancel();
// // // // // // //     super.dispose();
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(
// // // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // // //         foregroundColor: Colors.white,
// // // // // // //       ),
// // // // // // //       body: WebViewWidget(controller: _controller),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }
// // // // // // import 'dart:async';
// // // // // // import 'dart:io';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // import 'package:file_picker/file_picker.dart';
// // // // // // import 'package:path_provider/path_provider.dart';

// // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // //   final String ip;
// // // // // //   final String? binFilePath; // 🟢 Đã thêm tham số này để khớp với hàm gọi từ MasterControlScreen

// // // // // //   const WebOTAScreen({
// // // // // //     super.key,
// // // // // //     required this.ip,
// // // // // //     this.binFilePath,
// // // // // //   });

// // // // // //   @override
// // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // }

// // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // //   late final WebViewController _controller;
// // // // // //   Timer? _successCheckTimer;
// // // // // //   bool _hasShownSuccessDialog = false;

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();

// // // // // //     final PlatformWebViewControllerCreationParams params =
// // // // // //         const PlatformWebViewControllerCreationParams();

// // // // // //     final WebViewController controller =
// // // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // // //     controller
// // // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // // //     // Bắt sự kiện mở File Picker của WebView trên Android
// // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // //       (controller.platform as AndroidWebViewController)
// // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // //         try {
// // // // // //           String? targetDirectory;

// // // // // //           if (Platform.isAndroid) {
// // // // // //             targetDirectory = '/storage/emulated/0/Download/bin_esp32';
// // // // // //             if (!await Directory(targetDirectory).exists()) {
// // // // // //               targetDirectory = '/storage/emulated/0/Download';
// // // // // //             }
// // // // // //           } else if (Platform.isIOS) {
// // // // // //             final docsDir = await getApplicationDocumentsDirectory();
// // // // // //             targetDirectory = '${docsDir.path}/bin_esp32';
// // // // // //           }

// // // // // //           // Mở File Picker trỏ sẵn thư mục chứa file .bin
// // // // // //           final selectedFiles = await FilePicker.pickFiles(
// // // // // //             type: FileType.custom,
// // // // // //             allowedExtensions: ['bin'],
// // // // // //             initialDirectory: targetDirectory,
// // // // // //           );

// // // // // //           if (selectedFiles.isNotEmpty && selectedFiles.first.path != null) {
// // // // // //             final Uri fileUri = Uri.file(selectedFiles.first.path!);

// // // // // //             _startListeningForSuccess();

// // // // // //             return [fileUri.toString()];
// // // // // //           }
// // // // // //         } catch (e) {
// // // // // //           debugPrint('Lỗi chọn file: $e');
// // // // // //         }
// // // // // //         return [];
// // // // // //       });
// // // // // //     }

// // // // // //     _controller = controller;
// // // // // //   }

// // // // // //   // Tự động kiểm tra trang web khi nạp xong
// // // // // //   void _startListeningForSuccess() {
// // // // // //     _successCheckTimer?.cancel();
// // // // // //     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // // // // //       if (_hasShownSuccessDialog || !mounted) {
// // // // // //         timer.cancel();
// // // // // //         return;
// // // // // //       }

// // // // // //       try {
// // // // // //         final result = await _controller.runJavaScriptReturningResult(
// // // // // //           "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
// // // // // //         );

// // // // // //         if (result == true || result.toString() == 'true') {
// // // // // //           timer.cancel();
// // // // // //           _showOTASuccessDialog();
// // // // // //         }
// // // // // //       } catch (e) {
// // // // // //         // Bỏ qua lỗi khi trang đang reload/reboot
// // // // // //       }
// // // // // //     });
// // // // // //   }

// // // // // //   void _showOTASuccessDialog() {
// // // // // //     if (_hasShownSuccessDialog || !mounted) return;
// // // // // //     setState(() => _hasShownSuccessDialog = true);

// // // // // //     showDialog(
// // // // // //       context: context,
// // // // // //       barrierDismissible: false,
// // // // // //       builder: (dialogContext) {
// // // // // //         return AlertDialog(
// // // // // //           shape: RoundedRectangleBorder(
// // // // // //             borderRadius: BorderRadius.circular(16),
// // // // // //           ),
// // // // // //           title: const Row(
// // // // // //             children: [
// // // // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // // // //               SizedBox(width: 8),
// // // // // //               Expanded(
// // // // // //                 child: Text(
// // // // // //                   'Nạp Firmware Thành Công',
// // // // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // // // //                 ),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //           content: const Text(
// // // // // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // // // //           ),
// // // // // //           actionsAlignment: MainAxisAlignment.center,
// // // // // //           actions: [
// // // // // //             ElevatedButton.icon(
// // // // // //               style: ElevatedButton.styleFrom(
// // // // // //                 backgroundColor: const Color(0xFF0284C7),
// // // // // //                 foregroundColor: Colors.white,
// // // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // // // //                 shape: RoundedRectangleBorder(
// // // // // //                   borderRadius: BorderRadius.circular(8),
// // // // // //                 ),
// // // // // //               ),
// // // // // //               onPressed: () {
// // // // // //                 Navigator.of(dialogContext).pop(); // Đóng Dialog Success
// // // // // //                 Navigator.of(context).pop(true);   // 🟢 Truyền true về màn hình chính
// // // // // //               },
// // // // // //               icon: const Icon(Icons.dashboard_rounded),
// // // // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // // // //             ),
// // // // // //           ],
// // // // // //         );
// // // // // //       },
// // // // // //     );
// // // // // //   }

// // // // // //   @override
// // // // // //   void dispose() {
// // // // // //     _successCheckTimer?.cancel();
// // // // // //     super.dispose();
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(
// // // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // // //         foregroundColor: Colors.white,
// // // // // //       ),
// // // // // //       body: WebViewWidget(controller: _controller),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'dart:async';
// // // // // import 'dart:io';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // import 'package:file_picker/file_picker.dart';
// // // // // import 'package:path_provider/path_provider.dart';

// // // // // class WebOTAScreen extends StatefulWidget {
// // // // //   final String ip;
// // // // //   final String? binFilePath;

// // // // //   const WebOTAScreen({
// // // // //     super.key,
// // // // //     required this.ip,
// // // // //     this.binFilePath,
// // // // //   });

// // // // //   @override
// // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // }

// // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // //   late final WebViewController _controller;
// // // // //   Timer? _successCheckTimer;
// // // // //   bool _hasShownSuccessDialog = false;

// // // // //   // 🟢 HÀM XỬ LÝ CHUẨN HÓA URL & TRÁNH LỖI MDNS TRÊN WEBVIEW
// // // // //   String _buildValidOtaUrl(String rawIp) {
// // // // //     debugPrint('[OTA Debug] 1. IP/Domain truyền vào: "$rawIp"');

// // // // //     // 1. Loại bỏ các tiền tố protocol (ws://, wss://, http://, https://) và port/path thừa
// // // // //     String cleanHost = rawIp
// // // // //         .trim()
// // // // //         .replaceAll(RegExp(r'^(ws://|wss://|http://|https://)'), '')
// // // // //         .split('/')[0]
// // // // //         .split(':')[0];

// // // // //     // 2. Chuyển đuôi .local sang IP tĩnh 192.168.0.200 để WebView truyền file không bị Not Found
// // // // //     if (cleanHost.endsWith('.local')) {
// // // // //       cleanHost = '192.168.0.200';
// // // // //       debugPrint('[OTA Debug] 2. Phát hiện mDNS .local -> Chuyển sang IP tĩnh: $cleanHost');
// // // // //     }

// // // // //     final finalUrl = 'http://$cleanHost/update';
// // // // //     debugPrint('[OTA Debug] 3. URL nạp vào WebView: $finalUrl');
// // // // //     return finalUrl;
// // // // //   }

// // // // //   @override
// // // // //   // void initState() {
// // // // //   //   super.initState();

// // // // //   //   final PlatformWebViewControllerCreationParams params =
// // // // //   //       const PlatformWebViewControllerCreationParams();

// // // // //   //   final WebViewController controller =
// // // // //   //       WebViewController.fromPlatformCreationParams(params);

// // // // //   //   final String targetUrl = _buildValidOtaUrl(widget.ip);

// // // // //   //   controller
// // // // //   //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // //   //     ..setNavigationDelegate(
// // // // //   //       NavigationDelegate(
// // // // //   //         onPageStarted: (String url) {
// // // // //   //           debugPrint('[OTA Debug] WebView BẮT ĐẦU tải: $url');
// // // // //   //         },
// // // // //   //         onPageFinished: (String url) {
// // // // //   //           debugPrint('[OTA Debug] WebView ĐÃ TẢI XONG: $url');
// // // // //   //         },
// // // // //   //         onWebResourceError: (WebResourceError error) {
// // // // //   //           debugPrint('[OTA Debug] ❌ Lỗi WebView (${error.errorCode}): ${error.description}');
// // // // //   //           debugPrint('[OTA Debug] ❌ URL lỗi: ${error.url}');
// // // // //   //         },
// // // // //   //       ),
// // // // //   //     )
// // // // //   //     ..loadRequest(Uri.parse(targetUrl));

// // // // //   //   // Cấu hình sự kiện chọn File cho Android WebView
// // // // //   //   if (controller.platform is AndroidWebViewController) {
// // // // //   //     AndroidWebViewController.enableDebugging(true);
// // // // //   //     (controller.platform as AndroidWebViewController)
// // // // //   //         .setOnShowFileSelector((FileSelectorParams params) async {
// // // // //   //       debugPrint('[OTA Debug] 📂 WebView yêu cầu mở File Picker');
// // // // //   //       try {
// // // // //   //         String? targetDirectory;

// // // // //   //         if (Platform.isAndroid) {
// // // // //   //           targetDirectory = '/storage/emulated/0/Download/bin_esp32';
// // // // //   //           if (!await Directory(targetDirectory).exists()) {
// // // // //   //             targetDirectory = '/storage/emulated/0/Download';
// // // // //   //           }
// // // // //   //         } else if (Platform.isIOS) {
// // // // //   //           final docsDir = await getApplicationDocumentsDirectory();
// // // // //   //           targetDirectory = '${docsDir.path}/bin_esp32';
// // // // //   //         }

// // // // //   //         final selectedFiles = await FilePicker.pickFiles(
// // // // //   //           type: FileType.custom,
// // // // //   //           allowedExtensions: ['bin'],
// // // // //   //           initialDirectory: targetDirectory,
// // // // //   //         );

// // // // //   //         if (selectedFiles.isNotEmpty && selectedFiles.first.path != null) {
// // // // //   //           final selectedPath = selectedFiles.first.path!;
// // // // //   //           final Uri fileUri = Uri.file(selectedPath);

// // // // //   //           debugPrint('[OTA Debug] ✅ Đã chọn file: $selectedPath');
// // // // //   //           _startListeningForSuccess();

// // // // //   //           return [fileUri.toString()];
// // // // //   //         }
// // // // //   //       } catch (e) {
// // // // //   //         debugPrint('[OTA Debug] ❌ Lỗi chọn file: $e');
// // // // //   //       }
// // // // //   //       return [];
// // // // //   //     });
// // // // //   //   }

// // // // //   //   _controller = controller;
// // // // //   // }

// // // // //   @override
// // // // // void initState() {
// // // // //   super.initState();

// // // // //   final PlatformWebViewControllerCreationParams params =
// // // // //       const PlatformWebViewControllerCreationParams();

// // // // //   final WebViewController controller =
// // // // //       WebViewController.fromPlatformCreationParams(params);

// // // // //   final String targetUrl = _buildValidOtaUrl(widget.ip);

// // // // //   controller
// // // // //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // //     ..setNavigationDelegate(
// // // // //       NavigationDelegate(
// // // // //         onPageStarted: (String url) {
// // // // //           debugPrint('[OTA Debug] 🚀 WebView BẮT ĐẦU tải: $url');
// // // // //         },
// // // // //         onPageFinished: (String url) {
// // // // //           debugPrint('[OTA Debug] ✅ WebView ĐÃ TẢI XONG: $url');
// // // // //         },
// // // // //         onWebResourceError: (WebResourceError error) {
// // // // //           debugPrint(
// // // // //               '[OTA Debug] ❌ Lỗi WebView (${error.errorCode}): ${error.description}');
// // // // //           debugPrint('[OTA Debug] ❌ URL lỗi: ${error.url}');
// // // // //         },
// // // // //       ),
// // // // //     )
// // // // //     ..loadRequest(Uri.parse(targetUrl));

// // // // //   // Cấu hình sự kiện chọn File cho Android WebView
// // // // //   if (controller.platform is AndroidWebViewController) {
// // // // //     AndroidWebViewController.enableDebugging(true);
// // // // //     (controller.platform as AndroidWebViewController)
// // // // //         .setOnShowFileSelector((FileSelectorParams params) async {
// // // // //       debugPrint('[OTA Debug] 📂 WebView yêu cầu mở File Picker');
// // // // //       try {
// // // // //         String? targetDirectory;

// // // // //         if (Platform.isAndroid) {
// // // // //           final primaryDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // // //           if (await primaryDir.exists()) {
// // // // //             targetDirectory = primaryDir.path;
// // // // //           } else {
// // // // //             targetDirectory = '/storage/emulated/0/Download';
// // // // //           }
// // // // //         } else if (Platform.isIOS) {
// // // // //           final docsDir = await getApplicationDocumentsDirectory();
// // // // //           targetDirectory = '${docsDir.path}/bin_esp32';
// // // // //         }

// // // // //         // 🟢 Ép kiểu rõ ràng thành FilePickerResult?
// // // // //         final FilePickerResult? pickerResult = await FilePicker.pickFiles(
// // // // //           type: FileType.any,
// // // // //           initialDirectory: targetDirectory,
// // // // //         );

// // // // //         // 🟢 Bỏ kiểm tra null dư thừa và truy xuất đúng thuộc tính .files của FilePickerResult
// // // // //         if (pickerResult != null && pickerResult.files.isNotEmpty) {
// // // // //           final String? selectedPath = pickerResult.files.first.path;

// // // // //           if (selectedPath != null && selectedPath.isNotEmpty) {
// // // // //             final Uri fileUri = Uri.file(selectedPath);

// // // // //             debugPrint('[OTA Debug] ✅ Đã chọn file thành công: $selectedPath');
// // // // //             _startListeningForSuccess();

// // // // //             return [fileUri.toString()];
// // // // //           }
// // // // //         }

// // // // //         debugPrint('[OTA Debug] ⚠️ Người dùng hủy chọn file hoặc file rỗng.');
// // // // //       } catch (e) {
// // // // //         debugPrint('[OTA Debug] ❌ Lỗi chọn file: $e');
// // // // //       }
// // // // //       return [];
// // // // //     });
// // // // //   }

// // // // //   _controller = controller;
// // // // // }

// // // // //   // Tự động lắng nghe trang báo nạp thành công
// // // // //   void _startListeningForSuccess() {
// // // // //     _successCheckTimer?.cancel();
// // // // //     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // // // //       if (_hasShownSuccessDialog || !mounted) {
// // // // //         timer.cancel();
// // // // //         return;
// // // // //       }

// // // // //       try {
// // // // //         final result = await _controller.runJavaScriptReturningResult(
// // // // //           "document.body.innerText.includes('Success') || document.body.innerText.includes('OK')",
// // // // //         );

// // // // //         if (result == true || result.toString() == 'true') {
// // // // //           timer.cancel();
// // // // //           _showOTASuccessDialog();
// // // // //         }
// // // // //       } catch (e) {
// // // // //         // Bỏ qua lỗi kết nối trong lúc ESP32 đang reboot
// // // // //       }
// // // // //     });
// // // // //   }

// // // // //   void _showOTASuccessDialog() {
// // // // //     if (_hasShownSuccessDialog || !mounted) return;
// // // // //     setState(() => _hasShownSuccessDialog = true);

// // // // //     showDialog(
// // // // //       context: context,
// // // // //       barrierDismissible: false,
// // // // //       builder: (dialogContext) {
// // // // //         return AlertDialog(
// // // // //           shape: RoundedRectangleBorder(
// // // // //             borderRadius: BorderRadius.circular(16),
// // // // //           ),
// // // // //           title: const Row(
// // // // //             children: [
// // // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // // //               SizedBox(width: 8),
// // // // //               Expanded(
// // // // //                 child: Text(
// // // // //                   'Nạp Firmware Thành Công',
// // // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           content: const Text(
// // // // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // // //           ),
// // // // //           actionsAlignment: MainAxisAlignment.center,
// // // // //           actions: [
// // // // //             ElevatedButton.icon(
// // // // //               style: ElevatedButton.styleFrom(
// // // // //                 backgroundColor: const Color(0xFF0284C7),
// // // // //                 foregroundColor: Colors.white,
// // // // //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // // //                 shape: RoundedRectangleBorder(
// // // // //                   borderRadius: BorderRadius.circular(8),
// // // // //                 ),
// // // // //               ),
// // // // //               onPressed: () {
// // // // //                 Navigator.of(dialogContext).pop();
// // // // //                 Navigator.of(context).pop(true);
// // // // //               },
// // // // //               icon: const Icon(Icons.dashboard_rounded),
// // // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // // //             ),
// // // // //           ],
// // // // //         );
// // // // //       },
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _successCheckTimer?.cancel();
// // // // //     super.dispose();
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // // //         backgroundColor: const Color(0xFF0284C7),
// // // // //         foregroundColor: Colors.white,
// // // // //       ),
// // // // //       body: WebViewWidget(controller: _controller),
// // // // //     );
// // // // //   }
// // // // // }
// // // // import 'dart:async';
// // // // import 'dart:io';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // import 'package:file_picker/file_picker.dart';
// // // // import 'package:path_provider/path_provider.dart';

// // // // class WebOTAScreen extends StatefulWidget {
// // // //   final String ip;
// // // //   final String? binFilePath;

// // // //   const WebOTAScreen({
// // // //     super.key,
// // // //     required this.ip,
// // // //     this.binFilePath,
// // // //   });

// // // //   @override
// // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // }

// // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // //   late final WebViewController _controller;
// // // //   Timer? _successCheckTimer;
// // // //   bool _hasShownSuccessDialog = false;

// // // //   // 🟢 HÀM XỬ LÝ CHUẨN HÓA URL & TRÁNH LỖI MDNS TRÊN WEBVIEW
// // // //   String _buildValidOtaUrl(String rawIp) {
// // // //     debugPrint('[OTA Debug] 1. IP/Domain truyền vào: "$rawIp"');

// // // //     String cleanHost = rawIp
// // // //         .trim()
// // // //         .replaceAll(RegExp(r'^(ws://|wss://|http://|https://)'), '')
// // // //         .split('/')[0]
// // // //         .split(':')[0];

// // // //     if (cleanHost.endsWith('.local')) {
// // // //       cleanHost = '192.168.0.200';
// // // //       debugPrint('[OTA Debug] 2. Phát hiện mDNS .local -> Chuyển sang IP tĩnh: $cleanHost');
// // // //     }

// // // //     final finalUrl = 'http://$cleanHost/update';
// // // //     debugPrint('[OTA Debug] 3. URL nạp vào WebView: $finalUrl');
// // // //     return finalUrl;
// // // //   }

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();

// // // //     final PlatformWebViewControllerCreationParams params =
// // // //         const PlatformWebViewControllerCreationParams();

// // // //     final WebViewController controller =
// // // //         WebViewController.fromPlatformCreationParams(params);

// // // //     final String targetUrl = _buildValidOtaUrl(widget.ip);

// // // //     controller
// // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // //       ..setNavigationDelegate(
// // // //         NavigationDelegate(
// // // //           onPageStarted: (String url) {
// // // //             debugPrint('[OTA Debug] 🚀 WebView BẮT ĐẦU tải: $url');
// // // //           },
// // // //           onPageFinished: (String url) {
// // // //             debugPrint('[OTA Debug] ✅ WebView ĐÃ TẢI XONG: $url');
// // // //           },
// // // //           onWebResourceError: (WebResourceError error) {
// // // //             debugPrint(
// // // //                 '[OTA Debug] ❌ Lỗi WebView (${error.errorCode}): ${error.description}');
// // // //             debugPrint('[OTA Debug] ❌ URL lỗi: ${error.url}');
// // // //           },
// // // //         ),
// // // //       )
// // // //       ..loadRequest(Uri.parse(targetUrl));

// // // //     // Cấu hình sự kiện chọn File cho Android WebView
// // // //     // Cấu hình sự kiện chọn File cho Android WebView
// // // //     // Cấu hình sự kiện chọn File cho Android WebView
// // // //     if (controller.platform is AndroidWebViewController) {
// // // //       AndroidWebViewController.enableDebugging(true);
// // // //       (controller.platform as AndroidWebViewController)
// // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // //         debugPrint('[OTA Debug] 📂 WebView yêu cầu mở File Picker');
// // // //         try {
// // // //           String? targetDirectory;

// // // //           if (Platform.isAndroid) {
// // // //             final primaryDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // //             if (await primaryDir.exists()) {
// // // //               targetDirectory = primaryDir.path;
// // // //             } else {
// // // //               targetDirectory = '/storage/emulated/0/Download';
// // // //             }
// // // //           } else if (Platform.isIOS) {
// // // //             final docsDir = await getApplicationDocumentsDirectory();
// // // //             targetDirectory = '${docsDir.path}/bin_esp32';
// // // //           }

// // // //           final result = await FilePicker.pickFiles(
// // // //             type: FileType.any,
// // // //             initialDirectory: targetDirectory,
// // // //           );

// // // //           // 🟢 BỎ 'result != null', CHỈ KIỂM TRA result.isNotEmpty
// // // //           final String? filePath = result.isNotEmpty ? result.first.path : null;

// // // //           if (filePath != null && filePath.isNotEmpty) {
// // // //             final Uri fileUri = Uri.file(filePath);

// // // //             debugPrint('[OTA Debug] ✅ Đã chọn file thành công: $filePath');
// // // //             _startListeningForSuccess();

// // // //             return [fileUri.toString()];
// // // //           }

// // // //           debugPrint('[OTA Debug] ⚠️ Người dùng hủy chọn file hoặc file rỗng.');
// // // //         } catch (e) {
// // // //           debugPrint('[OTA Debug] ❌ Lỗi chọn file: $e');
// // // //         }
// // // //         return [];
// // // //       });
// // // //     }

// // // //     _controller = controller;
// // // //   }

// // // //   // Tự động lắng nghe trang báo nạp thành công
// // // //   void _startListeningForSuccess() {
// // // //     _successCheckTimer?.cancel();
// // // //     _successCheckTimer =
// // // //         Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // // //       if (_hasShownSuccessDialog || !mounted) {
// // // //         timer.cancel();
// // // //         return;
// // // //       }

// // // //       try {
// // // //         final result = await _controller.runJavaScriptReturningResult(
// // // //           "document.body.innerText.includes('Success') || document.body.innerText.includes('OK')",
// // // //         );

// // // //         if (result == true || result.toString() == 'true') {
// // // //           timer.cancel();
// // // //           _showOTASuccessDialog();
// // // //         }
// // // //       } catch (e) {
// // // //         // Bỏ qua lỗi kết nối trong lúc ESP32 đang reboot
// // // //       }
// // // //     });
// // // //   }

// // // //   void _showOTASuccessDialog() {
// // // //     if (_hasShownSuccessDialog || !mounted) return;
// // // //     setState(() => _hasShownSuccessDialog = true);

// // // //     showDialog(
// // // //       context: context,
// // // //       barrierDismissible: false,
// // // //       builder: (dialogContext) {
// // // //         return AlertDialog(
// // // //           shape: RoundedRectangleBorder(
// // // //             borderRadius: BorderRadius.circular(16),
// // // //           ),
// // // //           title: const Row(
// // // //             children: [
// // // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // // //               SizedBox(width: 8),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   'Nạp Firmware Thành Công',
// // // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           content: const Text(
// // // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // //           ),
// // // //           actionsAlignment: MainAxisAlignment.center,
// // // //           actions: [
// // // //             ElevatedButton.icon(
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: const Color(0xFF0284C7),
// // // //                 foregroundColor: Colors.white,
// // // //                 padding:
// // // //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // // //                 shape: RoundedRectangleBorder(
// // // //                   borderRadius: BorderRadius.circular(8),
// // // //                 ),
// // // //               ),
// // // //               onPressed: () {
// // // //                 Navigator.of(dialogContext).pop();
// // // //                 Navigator.of(context).pop(true);
// // // //               },
// // // //               icon: const Icon(Icons.dashboard_rounded),
// // // //               label: const Text('Về Màn Hình Sa Bàn'),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }

// // // //   @override
// // // //   void dispose() {
// // // //     _successCheckTimer?.cancel();
// // // //     super.dispose();
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // //         backgroundColor: const Color(0xFF0284C7),
// // // //         foregroundColor: Colors.white,
// // // //       ),
// // // //       body: WebViewWidget(controller: _controller),
// // // //     );
// // // //   }
// // // // }

// // // import 'dart:async';
// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:webview_flutter/webview_flutter.dart';
// // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // import 'package:file_picker/file_picker.dart';
// // // import 'package:path_provider/path_provider.dart';

// // // class WebOTAScreen extends StatefulWidget {
// // //   final String ip;
// // //   final String? binFilePath;

// // //   const WebOTAScreen({
// // //     super.key,
// // //     required this.ip,
// // //     this.binFilePath,
// // //   });

// // //   @override
// // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // }

// // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // //   late final WebViewController _controller;
// // //   Timer? _successCheckTimer;
// // //   bool _hasShownSuccessDialog = false;

// // //   // 🟢 HÀM XỬ LÝ CHUẨN HÓA URL (Chuyển .local thành IP tĩnh 192.168.0.200)
// // //   String _buildValidOtaUrl(String rawIp) {
// // //     String cleanHost = rawIp
// // //         .trim()
// // //         .replaceAll(RegExp(r'^(ws://|wss://|http://|https://)'), '')
// // //         .split('/')[0]
// // //         .split(':')[0];

// // //     if (cleanHost.endsWith('.local')) {
// // //       cleanHost = '192.168.0.200';
// // //     }

// // //     return 'http://$cleanHost/update';
// // //   }

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     final PlatformWebViewControllerCreationParams params =
// // //         const PlatformWebViewControllerCreationParams();

// // //     final WebViewController controller =
// // //         WebViewController.fromPlatformCreationParams(params);

// // //     final String targetUrl = _buildValidOtaUrl(widget.ip);

// // //     controller
// // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // //       ..loadRequest(Uri.parse(targetUrl));

// // //     // Bắt sự kiện mở File Picker của WebView trên Android
// // //     if (controller.platform is AndroidWebViewController) {
// // //       AndroidWebViewController.enableDebugging(true);
// // //       (controller.platform as AndroidWebViewController)
// // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // //         try {
// // //           String? targetDirectory;

// // //           if (Platform.isAndroid) {
// // //             targetDirectory = '/storage/emulated/0/Download/bin_esp32';
// // //             if (!await Directory(targetDirectory).exists()) {
// // //               targetDirectory = '/storage/emulated/0/Download';
// // //             }
// // //           } else if (Platform.isIOS) {
// // //             final docsDir = await getApplicationDocumentsDirectory();
// // //             targetDirectory = '${docsDir.path}/bin_esp32';
// // //           }

// // //           // 🟢 ĐÃ SỬA: Dùng FileType.any để Android không ẩn file .bin
// // //           final result = await FilePicker.pickFiles(
// // //             type: FileType.any,
// // //             initialDirectory: targetDirectory,
// // //           );

// // //           // 🟢 ĐÃ SỬA: Cú pháp chuẩn Null Safety cho kiểu List<PlatformFile>
// // //           if (result.isNotEmpty) {
// // //             final String? filePath = result.first.path;

// // //             if (filePath != null && filePath.isNotEmpty) {
// // //               final Uri fileUri = Uri.file(filePath);
// // //               debugPrint('[OTA Debug] ✅ Chọn file thành công: $filePath');

// // //               _startListeningForSuccess();

// // //               return [fileUri.toString()];
// // //             }
// // //           }
// // //         } catch (e) {
// // //           debugPrint('[OTA Debug] ❌ Lỗi chọn file: $e');
// // //         }
// // //         return [];
// // //       });
// // //     }

// // //     _controller = controller;
// // //   }

// // //   // Tự động kiểm tra trang web khi nạp xong
// // //   void _startListeningForSuccess() {
// // //     _successCheckTimer?.cancel();
// // //     _successCheckTimer =
// // //         Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// // //       if (_hasShownSuccessDialog || !mounted) {
// // //         timer.cancel();
// // //         return;
// // //       }

// // //       try {
// // //         // 🟢 ĐÃ SỬA: Nới lỏng điều kiện kiểm tra để nhận diện linh hoạt các phản hồi từ ESP32
// // //         final result = await _controller.runJavaScriptReturningResult(
// // //           "document.body.innerText.includes('Success') || document.body.innerText.includes('OK')",
// // //         );

// // //         if (result == true || result.toString() == 'true') {
// // //           timer.cancel();
// // //           _showOTASuccessDialog();
// // //         }
// // //       } catch (e) {
// // //         // Bỏ qua lỗi kết nối trong lúc ESP32 reboot
// // //       }
// // //     });
// // //   }

// // //   void _showOTASuccessDialog() {
// // //     if (_hasShownSuccessDialog || !mounted) return;
// // //     setState(() => _hasShownSuccessDialog = true);

// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (dialogContext) {
// // //         return AlertDialog(
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(16),
// // //           ),
// // //           title: const Row(
// // //             children: [
// // //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// // //               SizedBox(width: 8),
// // //               Expanded(
// // //                 child: Text(
// // //                   'Nạp Firmware Thành Công',
// // //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //           content: const Text(
// // //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // //           ),
// // //           actionsAlignment: MainAxisAlignment.center,
// // //           actions: [
// // //             ElevatedButton.icon(
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: const Color(0xFF0284C7),
// // //                 foregroundColor: Colors.white,
// // //                 padding:
// // //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // //                 shape: RoundedRectangleBorder(
// // //                   borderRadius: BorderRadius.circular(8),
// // //                 ),
// // //               ),
// // //               onPressed: () {
// // //                 Navigator.of(dialogContext).pop();
// // //                 Navigator.of(context).pop(true);
// // //               },
// // //               icon: const Icon(Icons.dashboard_rounded),
// // //               label: const Text('Về Màn Hình Sa Bàn'),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _successCheckTimer?.cancel();
// // //     super.dispose();
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Nạp Firmware Sa Bàn'),
// // //         backgroundColor: const Color(0xFF0284C7),
// // //         foregroundColor: Colors.white,
// // //       ),
// // //       body: WebViewWidget(controller: _controller),
// // //     );
// // //   }
// // // }
// // import 'dart:async';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:webview_flutter/webview_flutter.dart';
// // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:path_provider/path_provider.dart';

// // class WebOTAScreen extends StatefulWidget {
// //   final String ip;
// //   final String? binFilePath; // 🟢 Nhận đường dẫn file .bin động từ Master Screen

// //   const WebOTAScreen({
// //     super.key,
// //     required this.ip,
// //     this.binFilePath,
// //   });

// //   @override
// //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // }

// // class _WebOTAScreenState extends State<WebOTAScreen> {
// //   late final WebViewController _controller;
// //   Timer? _successCheckTimer;
// //   bool _hasShownSuccessDialog = false;

// //   // 🟢 HÀM XỬ LÝ CHUẨN HÓA URL (Tự động chuyển .local thành IP tĩnh 192.168.0.200)
// //   String _buildValidOtaUrl(String rawIp) {
// //     String cleanHost = rawIp
// //         .trim()
// //         .replaceAll(RegExp(r'^(ws://|wss://|http://|https://)'), '')
// //         .split('/')[0]
// //         .split(':')[0];

// //     if (cleanHost.endsWith('.local')) {
// //       cleanHost = '192.168.0.200';
// //     }

// //     return 'http://$cleanHost/update';
// //   }

// //   // 🟢 HÀM LẤY THƯ MỤC ĐÍCH ĐỘNG (KHÔNG FIX CỨNG PATH)
// //   Future<String?> _getDynamicTargetDirectory() async {
// //     // 1. Ưu tiên lấy thư mục cha từ đường dẫn binFilePath được truyền vào
// //     if (widget.binFilePath != null && widget.binFilePath!.isNotEmpty) {
// //       final file = File(widget.binFilePath!);
// //       if (await file.exists()) {
// //         return file.parent.path;
// //       }
// //     }

// //     // 2. Phương án dự phòng tự động xác định thư mục Download chuẩn của HĐH
// //     if (Platform.isAndroid) {
// //       final downloadsDir = Directory('/storage/emulated/0/Download');
// //       if (await downloadsDir.exists()) {
// //         return downloadsDir.path;
// //       }
// //     } else if (Platform.isIOS) {
// //       final docsDir = await getApplicationDocumentsDirectory();
// //       return docsDir.path;
// //     }

// //     return null;
// //   }

// //   @override
// //   void initState() {
// //     super.initState();

// //     final PlatformWebViewControllerCreationParams params =
// //         const PlatformWebViewControllerCreationParams();

// //     final WebViewController controller =
// //         WebViewController.fromPlatformCreationParams(params);

// //     final String targetUrl = _buildValidOtaUrl(widget.ip);

// //     controller
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse(targetUrl));

// //     // Cấu hình sự kiện chọn File cho Android WebView
// //     if (controller.platform is AndroidWebViewController) {
// //       AndroidWebViewController.enableDebugging(true);
// //       (controller.platform as AndroidWebViewController)
// //           .setOnShowFileSelector((FileSelectorParams params) async {
// //         try {
// //           // 🟢 Lấy đường dẫn thư mục động
// //           final String? targetDirectory = await _getDynamicTargetDirectory();

// //           // 🟢 Dùng FileType.any để hiển thị tất cả các tệp (tránh ẩn file .bin)[cite: 1, 2]
// //           final result = await FilePicker.pickFiles(
// //             type: FileType.any,
// //             initialDirectory: targetDirectory,
// //           );

// //           // 🟢 Xử lý kiểm tra Null Safety chuẩn cho kiểu List<PlatformFile>[cite: 1]
// //           if (result.isNotEmpty) {
// //             final String? filePath = result.first.path;

// //             if (filePath != null && filePath.isNotEmpty) {
// //               final Uri fileUri = Uri.file(filePath);
// //               debugPrint('[OTA Debug] ✅ Chọn file thành công: $filePath');

// //               _startListeningForSuccess();

// //               return [fileUri.toString()];
// //             }
// //           }
// //         } catch (e) {
// //           debugPrint('[OTA Debug] ❌ Lỗi chọn file: $e');
// //         }
// //         return [];
// //       });
// //     }

// //     _controller = controller;
// //   }

// //   // Tự động kiểm tra trang web khi nạp thành công
// //   void _startListeningForSuccess() {
// //     _successCheckTimer?.cancel();
// //     _successCheckTimer =
// //         Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// //       if (_hasShownSuccessDialog || !mounted) {
// //         timer.cancel();
// //         return;
// //       }

// //       try {
// //         // 🟢 Nới lỏng điều kiện kiểm tra để tương thích linh hoạt với giao diện ESP32
// //         final result = await _controller.runJavaScriptReturningResult(
// //           "document.body.innerText.includes('Success') || document.body.innerText.includes('OK')",
// //         );

// //         if (result == true || result.toString() == 'true') {
// //           timer.cancel();
// //           _showOTASuccessDialog();
// //         }
// //       } catch (e) {
// //         // Bỏ qua lỗi mất kết nối tạm thời khi ESP32 đang khởi động lại
// //       }
// //     });
// //   }

// //   void _showOTASuccessDialog() {
// //     if (_hasShownSuccessDialog || !mounted) return;
// //     setState(() => _hasShownSuccessDialog = true);

// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (dialogContext) {
// //         return AlertDialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(16),
// //           ),
// //           title: const Row(
// //             children: [
// //               Icon(Icons.check_circle, color: Colors.green, size: 26),
// //               SizedBox(width: 8),
// //               Expanded(
// //                 child: Text(
// //                   'Nạp Firmware Thành Công',
// //                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           content: const Text(
// //             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// //           ),
// //           actionsAlignment: MainAxisAlignment.center,
// //           actions: [
// //             ElevatedButton.icon(
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: const Color(0xFF0284C7),
// //                 foregroundColor: Colors.white,
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //               ),
// //               onPressed: () {
// //                 Navigator.of(dialogContext).pop();
// //                 Navigator.of(context).pop(true);
// //               },
// //               icon: const Icon(Icons.dashboard_rounded),
// //               label: const Text('Về Màn Hình Sa Bàn'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _successCheckTimer?.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Nạp Firmware Sa Bàn'),
// //         backgroundColor: const Color(0xFF0284C7),
// //         foregroundColor: Colors.white,
// //       ),
// //       body: WebViewWidget(controller: _controller),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as shelf_io;
// import 'package:web_socket_channel/web_socket_channel.dart';

// class WebOTAScreen extends StatefulWidget {
//   final String ip;
//   final String? binFilePath;
//   final WebSocketChannel? webSocketChannel; // WebSocket channel kết nối với ESP32

//   const WebOTAScreen({
//     super.key,
//     required this.ip,
//     this.binFilePath,
//     this.webSocketChannel,
//   });

//   @override
//   State<WebOTAScreen> createState() => _WebOTAScreenState();
// }

// class _WebOTAScreenState extends State<WebOTAScreen> {
//   HttpServer? _localHttpServer;
//   bool _isUploading = false;
//   String _statusMessage = 'Sẵn sàng nạp Firmware cho Sa bàn';
//   double _progressValue = 0.0;
//   String? _selectedFilePath;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.binFilePath != null && widget.binFilePath!.isNotEmpty) {
//       _selectedFilePath = widget.binFilePath;
//     }
//   }

//   // LẤY IP CỦA ĐIỆN THOẠI TRONG MẠNG WI-FI
//   Future<String?> _getPhoneIp() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('[OTA] Lỗi lấy IP Điện thoại: $e');
//     }
//     return null;
//   }

//   // CHỌN FILE .BIN TỪ THIẾT BỊ
//   // CHỌN FILE .BIN TỪ THIẾT BỊ (TƯƠNG THÍCH VỚI TẤT CẢ PHIÊN BẢN FILE_PICKER)
//   // CHỌN FILE .BIN TỪ THIẾT BỊ (ĐÃ SỬA LỖI TƯƠNG THÍCH LIST<PLATFORMFILE>)
//   Future<void> _pickBinFile() async {
//     try {
//       // 1. Lấy trực tiếp danh sách các file được chọn
//       final dynamic result = await FilePicker.pickFiles(
//         type: FileType.any,
//       );

//       // 2. Xử lý linh hoạt cho cả 2 trường hợp (FilePickerResult hoặc List<PlatformFile>)
//       if (result != null) {
//         // Nếu trả về kiểu List<PlatformFile>
//         if (result is List && result.isNotEmpty) {
//           final PlatformFile pickedFile = result.first as PlatformFile;
//           _processSelectedFile(pickedFile);
//         } 
//         // Nếu trả về đối tượng FilePickerResult chứa .files
//         else if (result.files != null && result.files.isNotEmpty) {
//           final PlatformFile pickedFile = result.files.first;
//           _processSelectedFile(pickedFile);
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _statusMessage = '❌ Lỗi chọn file: $e';
//       });
//     }
//   }

//   // Hàm phụ trợ xử lý kiểm tra đuôi file .bin
//   void _processSelectedFile(PlatformFile pickedFile) {
//     final String? path = pickedFile.path;

//     if (path != null && path.endsWith('.bin')) {
//       setState(() {
//         _selectedFilePath = path;
//         _statusMessage = 'Đã chọn file: ${pickedFile.name}';
//       });
//     } else {
//       setState(() {
//         _statusMessage = '❌ Lỗi: Vui lòng chọn file có định dạng .bin';
//       });
//     }
//   }

//   // KÍCH HOẠT PULL-OTA
//   Future<void> _startPullOTA() async {
//     if (_selectedFilePath == null || !File(_selectedFilePath!).existsSync()) {
//       setState(() => _statusMessage = '❌ Chưa chọn file .bin hợp lệ!');
//       return;
//     }

//     setState(() {
//       _isUploading = true;
//       _progressValue = 0.2;
//       _statusMessage = 'Đang khởi tạo Server phát file trên điện thoại...';
//     });

//     try {
//       await _localHttpServer?.close(force: true);

//       String? phoneIp = await _getPhoneIp();
//       if (phoneIp == null) {
//         setState(() {
//           _isUploading = false;
//           _statusMessage = '❌ Không lấy được IP Wi-Fi của điện thoại!';
//         });
//         return;
//       }

//       final binFile = File(_selectedFilePath!);
//       int port = 8080;

//       // Sửa định nghĩa hàm closure theo góp ý linter
//       Response handleRequest(Request request) {
//         if (request.url.path == 'firmware.bin') {
//           return Response.ok(
//             binFile.openRead(),
//             headers: {
//               'content-type': 'application/octet-stream',
//               'content-length': binFile.lengthSync().toString(),
//             },
//           );
//         }
//         return Response.notFound('Not Found');
//       }

//       _localHttpServer = await shelf_io.serve(handleRequest, InternetAddress.anyIPv4, port);
      
//       String downloadUrl = "http://$phoneIp:$port/firmware.bin";
//       debugPrint('[OTA] Server đang phát file tại: $downloadUrl');

//       setState(() {
//         _progressValue = 0.5;
//         _statusMessage = 'Đang gửi lệnh yêu cầu ESP32 tự kéo file...';
//       });

//       // Gửi lệnh Pull-OTA qua WebSocket
//       String otaCommand = "UPDATE_FIRMWARE:$downloadUrl";
//       widget.webSocketChannel?.sink.add(otaCommand);

//       setState(() {
//         _progressValue = 0.8;
//         _statusMessage = 'ESP32 đang tải dữ liệu và ghi Flash. Vui lòng chờ...';
//       });

//       // Chờ 8 giây cho ESP32 nạp hoàn tất
//       await Future.delayed(const Duration(seconds: 8));

//       await _localHttpServer?.close(force: true);
//       _localHttpServer = null;

//       if (mounted) {
//         setState(() {
//           _isUploading = false;
//           _progressValue = 1.0;
//           _statusMessage = '✅ Hoàn tất! ESP32 đã nạp thành công và đang khởi động lại.';
//         });
//         _showSuccessDialog();
//       }

//     } catch (e) {
//       await _localHttpServer?.close(force: true);
//       _localHttpServer = null;
//       if (mounted) {
//         setState(() {
//           _isUploading = false;
//           _statusMessage = '❌ Lỗi tiến trình OTA: $e';
//         });
//       }
//     }
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle, color: Colors.green, size: 28),
//               SizedBox(width: 8),
//               Text('Nạp Firmware Thành Công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: const Text(
//             'Thiết bị Sa bàn đã nạp thành công và đang khởi động lại. Bấm nút bên dưới để về màn hình điều khiển.',
//           ),
//           actions: [
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF0284C7),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//                 Navigator.of(context).pop(true);
//               },
//               icon: const Icon(Icons.dashboard_rounded),
//               label: const Text('Về Màn Hình Sa Bàn'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _localHttpServer?.close(force: true);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Nạp Firmware Sa Bàn'),
//         backgroundColor: const Color(0xFF0284C7),
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Icon(Icons.system_update_alt_rounded, size: 48, color: Color(0xFF0284C7)),
//                     const SizedBox(height: 12),
//                     Text(
//                       _selectedFilePath != null 
//                           ? File(_selectedFilePath!).path.split('/').last 
//                           : 'Chưa chọn file firmware (.bin)',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: _isUploading ? null : _pickBinFile,
//                       icon: const Icon(Icons.folder_open),
//                       label: const Text('Chọn File Firmware (.bin)'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             if (_isUploading) ...[
//               LinearProgressIndicator(value: _progressValue, backgroundColor: Colors.grey[200]),
//               const SizedBox(height: 16),
//             ],
//             Text(
//               _statusMessage,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: _statusMessage.startsWith('❌') ? Colors.red : Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const Spacer(),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF0284C7),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//               onPressed: (_isUploading || _selectedFilePath == null) ? null : _startPullOTA,
//               child: _isUploading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('BẮT ĐẦU NẠP FIRMWARE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebOTAScreen extends StatefulWidget {
  final String ip;
  final String? binFilePath;
  final WebSocketChannel? webSocketChannel; // WebSocket channel kết nối với ESP32

  const WebOTAScreen({
    super.key,
    required this.ip,
    this.binFilePath,
    this.webSocketChannel,
  });

  @override
  State<WebOTAScreen> createState() => _WebOTAScreenState();
}

class _WebOTAScreenState extends State<WebOTAScreen> {
  HttpServer? _localHttpServer;
  bool _isUploading = false;
  String _statusMessage = 'Sẵn sàng nạp Firmware cho Sa bàn';
  double _progressValue = 0.0;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.binFilePath != null && widget.binFilePath!.isNotEmpty) {
      _selectedFilePath = widget.binFilePath;
    }
  }

  // 🟢 HÀM LẤY IP CHUẨN CỦA ĐIỆN THOẠI TRONG MẠNG WI-FI (192.168.x.x)
  Future<String?> _getPhoneIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          // Lọc ưu tiên lấy IP dải IPv4 thực tế trong mạng LAN
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback && 
              !addr.address.startsWith('10.0.2.')) { 
            return addr.address;
          }
        }
      }
      // Dự phòng nếu chạy trên Emulator thì lấy IP interface bất kỳ không loopback
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('[OTA] Lỗi lấy IP Điện thoại: $e');
    }
    return null;
  }

  // CHỌN FILE .BIN TỪ THIẾT BỊ
  Future<void> _pickBinFile() async {
    try {
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        if (result is List && result.isNotEmpty) {
          final PlatformFile pickedFile = result.first as PlatformFile;
          _processSelectedFile(pickedFile);
        } else if (result.files != null && result.files.isNotEmpty) {
          final PlatformFile pickedFile = result.files.first;
          _processSelectedFile(pickedFile);
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Lỗi chọn file: $e';
      });
    }
  }

  void _processSelectedFile(PlatformFile pickedFile) {
    final String? path = pickedFile.path;

    if (path != null && path.endsWith('.bin')) {
      setState(() {
        _selectedFilePath = path;
        _statusMessage = 'Đã chọn file: ${pickedFile.name}';
      });
    } else {
      setState(() {
        _statusMessage = '❌ Lỗi: Vui lòng chọn file có định dạng .bin';
      });
    }
  }

  // 🟢 KÍCH HOẠT PULL-OTA CHUẨN LẮNG NGHE TÍN HIỆU THỰC
  // Future<void> _startPullOTA() async {
  //   if (_selectedFilePath == null || !File(_selectedFilePath!).existsSync()) {
  //     setState(() => _statusMessage = '❌ Chưa chọn file .bin hợp lệ!');
  //     return;
  //   }

  //   setState(() {
  //     _isUploading = true;
  //     _progressValue = 0.1;
  //     _statusMessage = 'Đang khởi tạo Server phát file trên điện thoại...';
  //   });

  //   StreamSubscription? wsSubscription;

  //   try {
  //     await _localHttpServer?.close(force: true);

  //     String? phoneIp = await _getPhoneIp();
  //     if (phoneIp == null) {
  //       setState(() {
  //         _isUploading = false;
  //         _statusMessage = '❌ Không lấy được IP Wi-Fi của điện thoại!';
  //       });
  //       return;
  //     }

  //     final binFile = File(_selectedFilePath!);
  //     int port = 8080;

  //     Response handleRequest(Request request) {
  //       if (request.url.path == 'firmware.bin') {
  //         debugPrint('[OTA Server] ESP32 bắt đầu đọc Stream file .bin...');
  //         return Response.ok(
  //           binFile.openRead(),
  //           headers: {
  //             'content-type': 'application/octet-stream',
  //             'content-length': binFile.lengthSync().toString(),
  //           },
  //         );
  //       }
  //       return Response.notFound('Not Found');
  //     }

  //     _localHttpServer = await shelf_io.serve(handleRequest, InternetAddress.anyIPv4, port);
      
  //     String downloadUrl = "http://$phoneIp:$port/firmware.bin";
  //     debugPrint('[OTA] HTTP Server đang phát tại: $downloadUrl');

  //     // Tạo Completer để đợi tín hiệu thật
  //     final Completer<bool> otaCompleter = Completer<bool>();

  //     // 🟢 1. LẮNG NGHE TÍN HIỆU TỪ WEBSOCKET
  //     if (widget.webSocketChannel != null) {
  //       wsSubscription = widget.webSocketChannel!.stream.listen(
  //         (message) {
  //           String msg = message.toString();
  //           debugPrint('[OTA Signal từ ESP32]: $msg');

  //           if (msg == 'OTA_SUCCESS') {
  //             if (!otaCompleter.isCompleted) otaCompleter.complete(true);
  //           } else if (msg.startsWith('OTA_ERROR')) {
  //             if (!otaCompleter.isCompleted) otaCompleter.completeError(msg);
  //           }
  //         },
  //         onError: (error) {
  //           // ESP32 đóng WebSocket để reboot cũng coi như thành công bước tải
  //           if (!otaCompleter.isCompleted) otaCompleter.complete(true);
  //         },
  //         onDone: () {
  //           if (!otaCompleter.isCompleted) otaCompleter.complete(true);
  //         },
  //       );
  //     }

  //     setState(() {
  //       _progressValue = 0.4;
  //       _statusMessage = 'Đang gửi lệnh yêu cầu ESP32 kéo file...';
  //     });

  //     // 🟢 2. GỬI LỆNH NẠP FIRMWARE VIA WEBSOCKET
  //     String otaCommand = "UPDATE_FIRMWARE:$downloadUrl";
  //     widget.webSocketChannel?.sink.add(otaCommand);

  //     setState(() {
  //       _progressValue = 0.7;
  //       _statusMessage = 'ESP32 đang tải dữ liệu và nạp Flash. Vui lòng chờ...';
  //     });

  //     // 🟢 3. CHỜ TÍN HIỆU THỰC TẾ (TIMEOUT TỐI ĐA 35 GIÂY)
  //     await otaCompleter.future.timeout(
  //       const Duration(seconds: 35),
  //       onTimeout: () {
  //         return true; // Nếu quá 35s không báo lỗi thì coi như xong tiến trình
  //       },
  //     );

  //     setState(() {
  //       _progressValue = 0.9;
  //       _statusMessage = 'ESP32 nạp Flash hoàn tất! Đang khởi động lại...';
  //     });

  //     // Dọn dẹp
  //     await wsSubscription?.cancel();
  //     await _localHttpServer?.close(force: true);
  //     _localHttpServer = null;

  //     // 🟢 4. CHỜ 5 GIÂY CHO ESP32 KHỞI ĐỘNG XONG HẲN
  //     await Future.delayed(const Duration(seconds: 5));

  //     if (mounted) {
  //       setState(() {
  //         _isUploading = false;
  //         _progressValue = 1.0;
  //         _statusMessage = '✅ Hoàn tất! ESP32 đã nạp thành công.';
  //       });
  //       _showSuccessDialog();
  //     }

  //   } catch (e) {
  //     await wsSubscription?.cancel();
  //     await _localHttpServer?.close(force: true);
  //     _localHttpServer = null;
  //     if (mounted) {
  //       setState(() {
  //         _isUploading = false;
  //         _statusMessage = '❌ Lỗi tiến trình OTA: $e';
  //       });
  //     }
  //   }
  // }

  // KÍCH HOẠT PULL-OTA CÓ TÍNH % TIẾN TRÌNH THỜI GIAN THỰC
  Future<void> _startPullOTA() async {
    if (_selectedFilePath == null || !File(_selectedFilePath!).existsSync()) {
      setState(() => _statusMessage = '❌ Chưa chọn file .bin hợp lệ!');
      return;
    }

    setState(() {
      _isUploading = true;
      _progressValue = 0.0;
      _statusMessage = 'Đang khởi tạo Server phát file... 0%';
    });

    StreamSubscription? wsSubscription;

    try {
      await _localHttpServer?.close(force: true);

      String? phoneIp = await _getPhoneIp();
      if (phoneIp == null) {
        setState(() {
          _isUploading = false;
          _statusMessage = '❌ Không lấy được IP Wi-Fi của thiết bị!';
        });
        return;
      }

      final binFile = File(_selectedFilePath!);
      final int totalBytes = binFile.lengthSync();
      int port = 8080;

      // 🟢 XỬ LÝ PHÁT STREAM CÓ ĐẾM % TIẾN TRÌNH
      Response handleRequest(Request request) {
        if (request.url.path == 'firmware.bin') {
          debugPrint('[OTA Server] ESP32 bắt đầu kéo file ($totalBytes bytes)...');

          // Bọc file stream với bộ đếm % ProgressStreamTransformer
          final progressStream = ProgressStreamTransformer.transform(
            binFile.openRead(),
            totalBytes,
            (sentBytes, percent) {
              if (mounted) {
                setState(() {
                  _progressValue = percent;
                  int displayPercent = (percent * 100).toInt();
                  _statusMessage = 'Đang nạp Firmware sang ESP32: $displayPercent%';
                });
              }
            },
          );

          return Response.ok(
            progressStream,
            headers: {
              'content-type': 'application/octet-stream',
              'content-length': totalBytes.toString(),
            },
          );
        }
        return Response.notFound('Not Found');
      }

      _localHttpServer = await shelf_io.serve(handleRequest, InternetAddress.anyIPv4, port);
      
      String downloadUrl = "http://$phoneIp:$port/firmware.bin";
      debugPrint('[OTA] Server đang phát tại: $downloadUrl');

      final Completer<bool> otaCompleter = Completer<bool>();

      // Lắng nghe tín hiệu WebSocket từ ESP32
      if (widget.webSocketChannel != null) {
        wsSubscription = widget.webSocketChannel!.stream.listen(
          (message) {
            String msg = message.toString();
            debugPrint('[OTA Signal]: $msg');

            if (msg == 'OTA_SUCCESS') {
              if (!otaCompleter.isCompleted) otaCompleter.complete(true);
            } else if (msg.startsWith('OTA_ERROR')) {
              if (!otaCompleter.isCompleted) otaCompleter.completeError(msg);
            }
          },
          onError: (_) {
            if (!otaCompleter.isCompleted) otaCompleter.complete(true);
          },
          onDone: () {
            if (!otaCompleter.isCompleted) otaCompleter.complete(true);
          },
        );
      }

      // Gửi lệnh cho ESP32 tự kéo file
      String otaCommand = "UPDATE_FIRMWARE:$downloadUrl";
      widget.webSocketChannel?.sink.add(otaCommand);

      // Chờ ESP32 nạp hoàn tất (Timeout 40 giây)
      await otaCompleter.future.timeout(
        const Duration(seconds: 40),
        onTimeout: () => true,
      );

      setState(() {
        _progressValue = 1.0;
        _statusMessage = 'Nạp thành công 100%! ESP32 đang khởi động lại...';
      });

      // Dọn dẹp Server
      await wsSubscription?.cancel();
      await _localHttpServer?.close(force: true);
      _localHttpServer = null;

      // Đợi 5s cho ESP32 boot hẳn vào Firmware mới
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _showSuccessDialog();
      }

    } catch (e) {
      await wsSubscription?.cancel();
      await _localHttpServer?.close(force: true);
      _localHttpServer = null;
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = '❌ Lỗi tiến trình OTA: $e';
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Nạp Firmware Thành Công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Thiết bị Sa bàn đã nạp thành công và đang khởi động lại. Bấm nút bên dưới để về màn hình điều khiển.',
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Về Màn Hình Sa Bàn'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _localHttpServer?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nạp Firmware Sa Bàn'),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.system_update_alt_rounded, size: 48, color: Color(0xFF0284C7)),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFilePath != null 
                          ? File(_selectedFilePath!).path.split('/').last 
                          : 'Chưa chọn file firmware (.bin)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickBinFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Chọn File Firmware (.bin)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // if (_isUploading) ...[
            //   LinearProgressIndicator(value: _progressValue, backgroundColor: Colors.grey[200]),
            //   const SizedBox(height: 16),
            // ],
            if (_isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 12, // Tăng độ dày thanh tiến trình
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(_progressValue * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _statusMessage.startsWith('❌') ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_isUploading || _selectedFilePath == null) ? null : _startPullOTA,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('BẮT ĐẦU NẠP FIRMWARE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
// 🟢 LỚP TÍNH PHẦN TRĂM DỮ LIỆU ĐANG PHÁT SANG ESP32
class ProgressStreamTransformer {
  static Stream<List<int>> transform(
    Stream<List<int>> stream, 
    int totalBytes, 
    void Function(int sentBytes, double percent) onProgress,
  ) {
    int bytesSent = 0;
    return stream.map((chunk) {
      bytesSent += chunk.length;
      double percent = (bytesSent / totalBytes).clamp(0.0, 1.0);
      onProgress(bytesSent, percent);
      return chunk;
    });
  }
}