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

// // // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // // //       (controller.platform as AndroidWebViewController)
// // // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // // //         try {
// // // // // // //           // ✅ Bỏ dấu ? ở List<PlatformFile> vì phiên bản này không bao giờ null
// // // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // // //             type: FileType.any,
// // // // // // //           );

// // // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // // //             final Uri fileUri = Uri.file(files.first.path!);
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

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // // import 'package:file_picker/file_picker.dart';

// // // // // // // 🟢 IMPORT 2 FILE NÀY TRONG DỰ ÁN CỦA BẠN
// // // // // // import '../screens/connect_screen.dart';
// // // // // // import '../widgets/reconnect_dialog.dart';

// // // // // // class WebOTAScreen extends StatefulWidget {
// // // // // //   final String ip;
// // // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // // //   @override
// // // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // // }

// // // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // // //   late final WebViewController _controller;

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

// // // // // //     if (controller.platform is AndroidWebViewController) {
// // // // // //       AndroidWebViewController.enableDebugging(true);
// // // // // //       (controller.platform as AndroidWebViewController)
// // // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // // //         try {
// // // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // // //             type: FileType.any,
// // // // // //           );

// // // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // // //             final Uri fileUri = Uri.file(files.first.path!);

// // // // // //             // 🟢 TỰ ĐỘNG BẬT ĐẾM NGƯỜI VÀ RECONNECT SAU KHÌ TRUYỀN FILE
// // // // // //             // _startAutoReconnectFlow();

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

// // // // // //   // 🟢 HÀM KÍCH HOẠT ĐẾM NGƯỢC VÀ CHUYỂN MÀN HÌNH TỰ ĐỘNG KẾT NỐI
// // // // // //   void _startAutoReconnectFlow() {
// // // // // //     // Trễ 2.5 giây để WebView kịp gửi xong request HTTP POST chứa file .bin sang ESP32
// // // // // //     Future.delayed(const Duration(milliseconds: 2500), () {
// // // // // //       if (!mounted) return;

// // // // // //       showDialog(
// // // // // //         context: context,
// // // // // //         barrierDismissible: false, // Bắt buộc người dùng đợi đếm ngược
// // // // // //         builder: (dialogContext) {
// // // // // //           return ReconnectCountdownDialog(
// // // // // //             ip: widget.ip,
// // // // // //             onReconnect: (ip) {
// // // // // //               // 🚀 Thoát khỏi WebOTAScreen, về ConnectScreen và tự kích hoạt hàm _connect()
// // // // // //               Navigator.of(context).pushAndRemoveUntil(
// // // // // //                 MaterialPageRoute(
// // // // // //                   builder: (context) => ConnectScreen(autoConnectIp: ip),
// // // // // //                 ),
// // // // // //                 (route) => false,
// // // // // //               );
// // // // // //             },
// // // // // //           );
// // // // // //         },
// // // // // //       );
// // // // // //     });
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

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:webview_flutter/webview_flutter.dart';
// // // // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // // // import 'package:file_picker/file_picker.dart';

// // // // // class WebOTAScreen extends StatefulWidget {
// // // // //   final String ip;
// // // // //   const WebOTAScreen({super.key, required this.ip});

// // // // //   @override
// // // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // // }

// // // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // // //   late final WebViewController _controller;

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();

// // // // //     final PlatformWebViewControllerCreationParams params =
// // // // //         const PlatformWebViewControllerCreationParams();

// // // // //     final WebViewController controller =
// // // // //         WebViewController.fromPlatformCreationParams(params);

// // // // //     controller
// // // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // // // //     if (controller.platform is AndroidWebViewController) {
// // // // //       AndroidWebViewController.enableDebugging(true);
// // // // //       (controller.platform as AndroidWebViewController)
// // // // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // // // //         try {
// // // // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // // // //             type: FileType.any,
// // // // //           );

// // // // //           if (files.isNotEmpty && files.first.path != null) {
// // // // //             final Uri fileUri = Uri.file(files.first.path!);
// // // // //             // 🟢 Chỉ trả về đường dẫn file để WebView nhận file bình thường
// // // // //             return [fileUri.toString()];
// // // // //           }
// // // // //         } catch (e) {
// // // // //           debugPrint('Lỗi chọn file: $e');
// // // // //         }
// // // // //         return [];
// // // // //       });
// // // // //     }

// // // // //     _controller = controller;
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

// // // // import 'package:flutter/material.dart';
// // // // import 'package:webview_flutter/webview_flutter.dart';

// // // // class WebOTAScreen extends StatefulWidget {
// // // //   final String ip;
// // // //   const WebOTAScreen({super.key, required this.ip});

// // // //   @override
// // // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // // }

// // // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // // //   late final WebViewController _controller;
// // // //   bool _hasShownSuccessDialog = false;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _controller = WebViewController()
// // // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // // //       ..setNavigationDelegate(
// // // //         NavigationDelegate(
// // // //           onPageFinished: (String url) {
// // // //             // Lắng nghe khi URL hoặc DOM hoàn tất nạp thành công
// // // //             _checkOtaSuccess();
// // // //           },
// // // //         ),
// // // //       )
// // // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));
// // // //   }

// // // //   void _checkOtaSuccess() async {
// // // //     // Kích hoạt Dialog nếu phát hiện chữ "Success" hoặc tự bật sau khi hoàn tất
// // // //     if (_hasShownSuccessDialog) return;
    
// // // //     // Đợi 1 chút để user nhìn thấy màn hình Success
// // // //     await Future.delayed(const Duration(seconds: 1));
// // // //     if (mounted && !_hasShownSuccessDialog) {
// // // //       _showOTASuccessDialog();
// // // //     }
// // // //   }

// // // //   void _showOTASuccessDialog() {
// // // //     setState(() => _hasShownSuccessDialog = true);
// // // //     showDialog(
// // // //       context: context,
// // // //       barrierDismissible: false,
// // // //       builder: (context) {
// // // //         return AlertDialog(
// // // //           shape: RoundedRectangleBorder(
// // // //             borderRadius: BorderRadius.circular(16),
// // // //           ),
// // // //           title: const Row(
// // // //             children: [
// // // //               Icon(Icons.check_circle, color: Colors.green, size: 28),
// // // //               SizedBox(width: 10),
// // // //               Text('Nạp Firmware Thành Công!'),
// // // //             ],
// // // //           ),
// // // //           content: const Text(
// // // //             'Thiết bị Sa bàn đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
// // // //           ),
// // // //           actions: [
// // // //             ElevatedButton.icon(
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: Colors.blue.shade700,
// // // //                 foregroundColor: Colors.white,
// // // //                 shape: RoundedRectangleBorder(
// // // //                   borderRadius: BorderRadius.circular(8),
// // // //                 ),
// // // //               ),
// // // //               onPressed: () {
// // // //                 // Đóng Dialog và thoát WebOTAScreen quay về MasterControlScreen
// // // //                 Navigator.of(context).pop(); // Pop Dialog
// // // //                 Navigator.of(context).pop(); // Pop WebOTAScreen
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
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: const Text('Nạp Firmware Sa Bàn'),
// // // //       ),
// // // //       body: WebViewWidget(controller: _controller),
// // // //     );
// // // //   }
// // // // }
// // // import 'package:flutter/material.dart';
// // // import 'package:webview_flutter/webview_flutter.dart';
// // // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // // import 'package:file_picker/file_picker.dart';

// // // class WebOTAScreen extends StatefulWidget {
// // //   final String ip;
// // //   const WebOTAScreen({super.key, required this.ip});

// // //   @override
// // //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // // }

// // // class _WebOTAScreenState extends State<WebOTAScreen> {
// // //   late final WebViewController _controller;

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     final PlatformWebViewControllerCreationParams params =
// // //         const PlatformWebViewControllerCreationParams();

// // //     final WebViewController controller =
// // //         WebViewController.fromPlatformCreationParams(params);

// // //     controller
// // //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// // //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// // //     // 🟢 GIỮ NGUYÊN CODE FILE PICKER CHUẨN CỦA BẠN
// // //     if (controller.platform is AndroidWebViewController) {
// // //       AndroidWebViewController.enableDebugging(true);
// // //       (controller.platform as AndroidWebViewController)
// // //           .setOnShowFileSelector((FileSelectorParams params) async {
// // //         try {
// // //           final List<PlatformFile> files = await FilePicker.pickFiles(
// // //             type: FileType.any,
// // //           );

// // //           if (files.isNotEmpty && files.first.path != null) {
// // //             final Uri fileUri = Uri.file(files.first.path!);
// // //             return [fileUri.toString()];
// // //           }
// // //         } catch (e) {
// // //           debugPrint('Lỗi chọn file: $e');
// // //         }
// // //         return [];
// // //       });
// // //     }

// // //     _controller = controller;
// // //   }

// // //   // 🟢 THÊM POPUP THÔNG BÁO VÀ CHUYỂN HƯỚNG VỀ SA BÀN
// // //   void _showOTASuccessDialog() {
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
// // //             'Nếu ElegantOTA đã báo Success, bấm nút bên dưới để quay về màn hình điều khiển sa bàn.',
// // //           ),
// // //           actionsAlignment: MainAxisAlignment.center,
// // //           actions: [
// // //             ElevatedButton.icon(
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: const Color(0xFF0284C7),
// // //                 foregroundColor: Colors.white,
// // //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // //                 shape: RoundedRectangleBorder(
// // //                   borderRadius: BorderRadius.circular(8),
// // //                 ),
// // //               ),
// // //               onPressed: () {
// // //                 Navigator.of(dialogContext).pop(); // Đóng Dialog
// // //                 Navigator.of(context).pop(); // Thoát WebOTAScreen về MasterControlScreen
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
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Nạp Firmware Sa Bàn'),
// // //         backgroundColor: const Color(0xFF0284C7),
// // //         foregroundColor: Colors.white,
// // //         actions: [
// // //           // 🟢 NÚT "XONG" TRÊN APPBAR
// // //           TextButton.icon(
// // //             onPressed: _showOTASuccessDialog,
// // //             icon: const Icon(Icons.check, color: Colors.white),
// // //             label: const Text(
// // //               'Xong',
// // //               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //       body: WebViewWidget(controller: _controller),
// // //     );
// // //   }
// // // }
// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:webview_flutter/webview_flutter.dart';
// // import 'package:webview_flutter_android/webview_flutter_android.dart';
// // import 'package:file_picker/file_picker.dart';

// // class WebOTAScreen extends StatefulWidget {
// //   final String ip;
// //   const WebOTAScreen({super.key, required this.ip});

// //   @override
// //   State<WebOTAScreen> createState() => _WebOTAScreenState();
// // }

// // class _WebOTAScreenState extends State<WebOTAScreen> {
// //   late final WebViewController _controller;
// //   Timer? _successCheckTimer;
// //   bool _hasShownSuccessDialog = false;

// //   @override
// //   void initState() {
// //     super.initState();

// //     final PlatformWebViewControllerCreationParams params =
// //         const PlatformWebViewControllerCreationParams();

// //     final WebViewController controller =
// //         WebViewController.fromPlatformCreationParams(params);

// //     controller
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

// //     // Giữ nguyên logic chọn file ổn định của bạn
// //     if (controller.platform is AndroidWebViewController) {
// //       AndroidWebViewController.enableDebugging(true);
// //       (controller.platform as AndroidWebViewController)
// //           .setOnShowFileSelector((FileSelectorParams params) async {
// //         try {
// //           final List<PlatformFile> files = await FilePicker.pickFiles(
// //             type: FileType.any,
// //           );

// //           if (files.isNotEmpty && files.first.path != null) {
// //             final Uri fileUri = Uri.file(files.first.path!);
            
// //             // 🟢 Khi người dùng đã chọn file và bắt đầu nạp, khởi chạy bộ lắng nghe Success
// //             _startListeningForSuccess();
            
// //             return [fileUri.toString()];
// //           }
// //         } catch (e) {
// //           debugPrint('Lỗi chọn file: $e');
// //         }
// //         return [];
// //       });
// //     }

// //     _controller = controller;
// //   }

// //   // 🟢 TỰ ĐỘNG BẮT SỰ KIỆN SUCCESS
// //   void _startListeningForSuccess() {
// //     _successCheckTimer?.cancel();
// //     // Quét mỗi 1.5 giây sau khi chọn file để phát hiện chữ "Success"
// //     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
// //       if (_hasShownSuccessDialog || !mounted) {
// //         timer.cancel();
// //         return;
// //       }

// //       try {
// //         final result = await _controller.runJavaScriptReturningResult(
// //           "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
// //         );

// //         if (result == true || result.toString() == 'true') {
// //           timer.cancel();
// //           _showOTASuccessDialog();
// //         }
// //       } catch (e) {
// //         // Bỏ qua lỗi nếu trang web đang load lại
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
// //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //               ),
// //               onPressed: () {
// //                 Navigator.of(dialogContext).pop();
// //                 Navigator.of(context).pop();
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
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:file_picker/file_picker.dart';

// class WebOTAScreen extends StatefulWidget {
//   final String ip;
  
//   const WebOTAScreen({super.key, required this.ip});

//   @override
//   State<WebOTAScreen> createState() => _WebOTAScreenState();
// }

// class _WebOTAScreenState extends State<WebOTAScreen> {
//   late final WebViewController _controller;
//   Timer? _successCheckTimer;
//   bool _hasShownSuccessDialog = false;

//   @override
//   void initState() {
//     super.initState();

//     final PlatformWebViewControllerCreationParams params =
//         const PlatformWebViewControllerCreationParams();

//     final WebViewController controller =
//         WebViewController.fromPlatformCreationParams(params);

//     controller
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..loadRequest(Uri.parse('http://${widget.ip}/update'));

//     // Bắt sự kiện mở File Picker của WebView trên Android
//     if (controller.platform is AndroidWebViewController) {
//       AndroidWebViewController.enableDebugging(true);
//       (controller.platform as AndroidWebViewController)
//           .setOnShowFileSelector((FileSelectorParams params) async {
//         try {
//           String? targetDirectory;
//           if (Platform.isAndroid) {
//             targetDirectory = '/storage/emulated/0/Download/bin_esp32';
//             if (!await Directory(targetDirectory).exists()) {
//               targetDirectory = '/storage/emulated/0/Download';
//             }
//           }

//           // Mở File Picker (Mở thư mục bin_esp32 trên Android, mở Files trên iOS)
//           final selectedFiles = await FilePicker.pickFiles(
//             type: FileType.custom,
//             allowedExtensions: ['bin'],
//             initialDirectory: targetDirectory,
//           );

//           // 🟢 Đã bỏ "selectedFiles != null"
//           if (selectedFiles.isNotEmpty && selectedFiles.first.path != null) {
//             final Uri fileUri = Uri.file(selectedFiles.first.path!);
            
//             _startListeningForSuccess();
            
//             return [fileUri.toString()];
//           }
//         } catch (e) {
//           debugPrint('Lỗi chọn file: $e');
//         }
//         return [];
//       });
//     }

//     _controller = controller;
//   }

//   // Tự động kiểm tra trang web khi nạp xong
//   void _startListeningForSuccess() {
//     _successCheckTimer?.cancel();
//     _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
//       if (_hasShownSuccessDialog || !mounted) {
//         timer.cancel();
//         return;
//       }

//       try {
//         final result = await _controller.runJavaScriptReturningResult(
//           "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
//         );

//         if (result == true || result.toString() == 'true') {
//           timer.cancel();
//           _showOTASuccessDialog();
//         }
//       } catch (e) {
//         // Bỏ qua lỗi khi trang đang reload/reboot
//       }
//     });
//   }

//   void _showOTASuccessDialog() {
//     if (_hasShownSuccessDialog || !mounted) return;
//     setState(() => _hasShownSuccessDialog = true);

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle, color: Colors.green, size: 26),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Nạp Firmware Thành Công',
//                   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//           content: const Text(
//             'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
//           ),
//           actionsAlignment: MainAxisAlignment.center,
//           actions: [
//             ElevatedButton.icon(
//   style: ElevatedButton.styleFrom(
//     backgroundColor: const Color(0xFF0284C7),
//     foregroundColor: Colors.white,
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(8),
//     ),
//   ),
//   onPressed: () {
//     Navigator.of(dialogContext).pop(); // Đóng Dialog Success
//     Navigator.of(context).pop(true);   // 🟢 TRUYỀN `true` VỀ MÀN HÌNH CHÍNH
//   },
//   icon: const Icon(Icons.dashboard_rounded),
//   label: const Text('Về Màn Hình Sa Bàn'),
// ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _successCheckTimer?.cancel();
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
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class WebOTAScreen extends StatefulWidget {
  final String ip;
  final String? binFilePath; // 🟢 Đã thêm tham số này để khớp với hàm gọi từ MasterControlScreen

  const WebOTAScreen({
    super.key,
    required this.ip,
    this.binFilePath,
  });

  @override
  State<WebOTAScreen> createState() => _WebOTAScreenState();
}

class _WebOTAScreenState extends State<WebOTAScreen> {
  late final WebViewController _controller;
  Timer? _successCheckTimer;
  bool _hasShownSuccessDialog = false;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://${widget.ip}/update'));

    // Bắt sự kiện mở File Picker của WebView trên Android
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setOnShowFileSelector((FileSelectorParams params) async {
        try {
          String? targetDirectory;

          if (Platform.isAndroid) {
            targetDirectory = '/storage/emulated/0/Download/bin_esp32';
            if (!await Directory(targetDirectory).exists()) {
              targetDirectory = '/storage/emulated/0/Download';
            }
          } else if (Platform.isIOS) {
            final docsDir = await getApplicationDocumentsDirectory();
            targetDirectory = '${docsDir.path}/bin_esp32';
          }

          // Mở File Picker trỏ sẵn thư mục chứa file .bin
          final selectedFiles = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['bin'],
            initialDirectory: targetDirectory,
          );

          if (selectedFiles.isNotEmpty && selectedFiles.first.path != null) {
            final Uri fileUri = Uri.file(selectedFiles.first.path!);

            _startListeningForSuccess();

            return [fileUri.toString()];
          }
        } catch (e) {
          debugPrint('Lỗi chọn file: $e');
        }
        return [];
      });
    }

    _controller = controller;
  }

  // Tự động kiểm tra trang web khi nạp xong
  void _startListeningForSuccess() {
    _successCheckTimer?.cancel();
    _successCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_hasShownSuccessDialog || !mounted) {
        timer.cancel();
        return;
      }

      try {
        final result = await _controller.runJavaScriptReturningResult(
          "document.body.innerText.includes('Success') && document.body.innerText.includes('rebooting')",
        );

        if (result == true || result.toString() == 'true') {
          timer.cancel();
          _showOTASuccessDialog();
        }
      } catch (e) {
        // Bỏ qua lỗi khi trang đang reload/reboot
      }
    });
  }

  void _showOTASuccessDialog() {
    if (_hasShownSuccessDialog || !mounted) return;
    setState(() => _hasShownSuccessDialog = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nạp Firmware Thành Công',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Thiết bị Sa bàn đã nạp xong và đang khởi động lại. Bấm nút bên dưới để quay về màn hình điều khiển.',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng Dialog Success
                Navigator.of(context).pop(true);   // 🟢 Truyền true về màn hình chính
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
    _successCheckTimer?.cancel();
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
      body: WebViewWidget(controller: _controller),
    );
  }
}