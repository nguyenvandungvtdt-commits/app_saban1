// // // // // // // // import 'dart:io';
// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:path_provider/path_provider.dart';
// // // // // // // // import 'package:dio/dio.dart';
// // // // // // // // import 'package:media_scanner/media_scanner.dart';

// // // // // // // // class FirmwareService {
// // // // // // // //   static String? localDownloadedBinPath;

// // // // // // // //   /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
// // // // // // // //   /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
// // // // // // // //   static Future<String?> downloadToBinFolder(String downloadUrl, {String? version}) async {
// // // // // // // //     try {
// // // // // // // //       // 🟢 Khởi tạo giá trị mặc định để tránh lỗi "must be assigned before it can be used"
// // // // // // // //       Directory customFolder = await getTemporaryDirectory();

// // // // // // // //       if (Platform.isAndroid) {
// // // // // // // //         // --- CẤU HÌNH DÀNH CHO ANDROID ---
// // // // // // // //         final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // // // // // //         bool canWritePublic = false;
// // // // // // // //         try {
// // // // // // // //           if (!await publicDownloadDir.exists()) {
// // // // // // // //             await publicDownloadDir.create(recursive: true);
// // // // // // // //           }
// // // // // // // //           final testFile = File('${publicDownloadDir.path}/.test_write');
// // // // // // // //           await testFile.writeAsString('test');
// // // // // // // //           await testFile.delete();
// // // // // // // //           canWritePublic = true;
// // // // // // // //           customFolder = publicDownloadDir;
// // // // // // // //         } catch (_) {
// // // // // // // //           canWritePublic = false;
// // // // // // // //         }

// // // // // // // //         if (!canWritePublic) {
// // // // // // // //           final externalDir = await getExternalStorageDirectory();
// // // // // // // //           final fallbackDir = Directory('${externalDir?.path}/bin_esp32');
// // // // // // // //           if (!await fallbackDir.exists()) {
// // // // // // // //             await fallbackDir.create(recursive: true);
// // // // // // // //           }
// // // // // // // //           customFolder = fallbackDir;
// // // // // // // //         }
// // // // // // // //       } else if (Platform.isIOS) {
// // // // // // // //         // --- CẤU HÌNH DÀNH CHO IOS (APP STORE) ---
// // // // // // // //         final docsDir = await getApplicationDocumentsDirectory();
// // // // // // // //         final iosFolder = Directory('${docsDir.path}/bin_esp32');
// // // // // // // //         if (!await iosFolder.exists()) {
// // // // // // // //           await iosFolder.create(recursive: true);
// // // // // // // //         }
// // // // // // // //         customFolder = iosFolder;
// // // // // // // //       }

// // // // // // // //       // Xóa các file .bin cũ trong thư mục
// // // // // // // //       if (await customFolder.exists()) {
// // // // // // // //         final files = customFolder.listSync();
// // // // // // // //         for (var file in files) {
// // // // // // // //           if (file.path.endsWith('.bin')) {
// // // // // // // //             await file.delete();
// // // // // // // //           }
// // // // // // // //         }
// // // // // // // //       }

// // // // // // // //       final fileName = version != null ? 'firmware_v$version.bin' : 'firmware_latest.bin';
// // // // // // // //       final filePath = '${customFolder.path}/$fileName';

// // // // // // // //       debugPrint('[OTA] Đường dẫn lưu file (${Platform.operatingSystem}): $filePath');

// // // // // // // //       final dio = Dio();
// // // // // // // //       await dio.download(
// // // // // // // //         downloadUrl, 
// // // // // // // //         filePath,
// // // // // // // //         options: Options(
// // // // // // // //           responseType: ResponseType.bytes,
// // // // // // // //           followRedirects: true,
// // // // // // // //           maxRedirects: 10,
// // // // // // // //           headers: {
// // // // // // // //             'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
// // // // // // // //           },
// // // // // // // //         ),
// // // // // // // //       );

// // // // // // // //       final downloadedFile = File(filePath);
// // // // // // // //       if (await downloadedFile.exists()) {
// // // // // // // //         final fileSize = await downloadedFile.length();
// // // // // // // //         debugPrint('[OTA] Tải thành công! Kích thước: $fileSize bytes');

// // // // // // // //         if (fileSize > 50000) {
// // // // // // // //           localDownloadedBinPath = filePath;

// // // // // // // //           // Chỉ quét MediaScanner trên Android
// // // // // // // //           if (Platform.isAndroid) {
// // // // // // // //             try {
// // // // // // // //               await MediaScanner.loadMedia(path: filePath);
// // // // // // // //             } catch (e) {
// // // // // // // //               debugPrint('[OTA] Lỗi MediaScanner Android: $e');
// // // // // // // //             }
// // // // // // // //           }

// // // // // // // //           return filePath;
// // // // // // // //         } else {
// // // // // // // //           await downloadedFile.delete();
// // // // // // // //           throw Exception("File tải về quá nhỏ ($fileSize bytes).");
// // // // // // // //         }
// // // // // // // //       } else {
// // // // // // // //         throw Exception("Không thể tạo file tại đường dẫn chỉ định.");
// // // // // // // //       }

// // // // // // // //     } catch (e) {
// // // // // // // //       debugPrint('[OTA] Lỗi tải file Firmware: $e');
// // // // // // // //       return null;
// // // // // // // //     }
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'dart:io';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:path_provider/path_provider.dart';
// // // // // // // import 'package:dio/dio.dart';
// // // // // // // import 'package:media_scanner/media_scanner.dart';

// // // // // // // class FirmwareService {
// // // // // // //   static String? localDownloadedBinPath;
// // // // // // //   // 🟢 Thêm phương thức lấy thư mục lưu trữ tùy theo OS
// // // // // // //   static Future<Directory> getSavedBinFolder() async {
// // // // // // //     if (Platform.isAndroid) {
// // // // // // //       final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // // // // //       if (await publicDownloadDir.exists()) {
// // // // // // //         return publicDownloadDir;
// // // // // // //       }
// // // // // // //       final externalDir = await getExternalStorageDirectory();
// // // // // // //       return Directory('${externalDir?.path}/bin_esp32');
// // // // // // //     } else {
// // // // // // //       final docsDir = await getApplicationDocumentsDirectory();
// // // // // // //       return Directory('${docsDir.path}/bin_esp32');
// // // // // // //     }
// // // // // // //   }

// // // // // // //   // 🟢 Thêm phương thức tìm file .bin mới nhất trong thư mục
// // // // // // //   static Future<File?> getLatestDownloadedBinFile() async {
// // // // // // //     final folder = await getSavedBinFolder();
// // // // // // //     if (await folder.exists()) {
// // // // // // //       final files = folder.listSync().whereType<File>().where((f) => f.path.endsWith('.bin')).toList();
// // // // // // //       if (files.isNotEmpty) {
// // // // // // //         files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
// // // // // // //         return files.first;
// // // // // // //       }
// // // // // // //     }
// // // // // // //     return null;
// // // // // // //   }

// // // // // // //   /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
// // // // // // //   static Future<String?> downloadToBinFolder(
// // // // // // //     String downloadUrl, {
// // // // // // //     String? version,
// // // // // // //     void Function(int received, int total)? onProgress,
// // // // // // //   }) async {
// // // // // // //     try {
// // // // // // //       // 🟢 Khởi tạo giá trị mặc định để tránh lỗi "must be assigned before it can be used"
// // // // // // //       Directory customFolder = await getTemporaryDirectory();

// // // // // // //       if (Platform.isAndroid) {
// // // // // // //         // --- CẤU HÌNH DÀNH CHO ANDROID ---
// // // // // // //         final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // // // // //         bool canWritePublic = false;
// // // // // // //         try {
// // // // // // //           if (!await publicDownloadDir.exists()) {
// // // // // // //             await publicDownloadDir.create(recursive: true);
// // // // // // //           }
// // // // // // //           final testFile = File('${publicDownloadDir.path}/.test_write');
// // // // // // //           await testFile.writeAsString('test');
// // // // // // //           await testFile.delete();
// // // // // // //           canWritePublic = true;
// // // // // // //           customFolder = publicDownloadDir;
// // // // // // //         } catch (_) {
// // // // // // //           canWritePublic = false;
// // // // // // //         }

// // // // // // //         if (!canWritePublic) {
// // // // // // //           final externalDir = await getExternalStorageDirectory();
// // // // // // //           final fallbackDir = Directory('${externalDir?.path}/bin_esp32');
// // // // // // //           if (!await fallbackDir.exists()) {
// // // // // // //             await fallbackDir.create(recursive: true);
// // // // // // //           }
// // // // // // //           customFolder = fallbackDir;
// // // // // // //         }
// // // // // // //       } else if (Platform.isIOS) {
// // // // // // //         // --- CẤU HÌNH DÀNH CHO IOS / IPAD OS (APP STORE) ---
// // // // // // //         final docsDir = await getApplicationDocumentsDirectory();
// // // // // // //         final iosFolder = Directory('${docsDir.path}/bin_esp32');
// // // // // // //         if (!await iosFolder.exists()) {
// // // // // // //           await iosFolder.create(recursive: true);
// // // // // // //         }
// // // // // // //         customFolder = iosFolder;
// // // // // // //       }

// // // // // // //       // Xóa các file .bin cũ trong thư mục
// // // // // // //       if (await customFolder.exists()) {
// // // // // // //         final files = customFolder.listSync();
// // // // // // //         for (var file in files) {
// // // // // // //           if (file.path.endsWith('.bin')) {
// // // // // // //             await file.delete();
// // // // // // //           }
// // // // // // //         }
// // // // // // //       }

// // // // // // //       final fileName = version != null ? 'firmware_v$version.bin' : 'firmware_latest.bin';
// // // // // // //       final filePath = '${customFolder.path}/$fileName';

// // // // // // //       debugPrint('[OTA] Đường dẫn lưu file (${Platform.operatingSystem}): $filePath');

// // // // // // //       final dio = Dio();
// // // // // // //       await dio.download(
// // // // // // //         downloadUrl, 
// // // // // // //         filePath,
// // // // // // //         onReceiveProgress: (received, total) {
// // // // // // //           if (onProgress != null) {
// // // // // // //             onProgress(received, total);
// // // // // // //           }
// // // // // // //         },
// // // // // // //         options: Options(
// // // // // // //           responseType: ResponseType.bytes,
// // // // // // //           followRedirects: true,
// // // // // // //           maxRedirects: 10,
// // // // // // //           headers: {
// // // // // // //             'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
// // // // // // //           },
// // // // // // //         ),
// // // // // // //       );

// // // // // // //       final downloadedFile = File(filePath);
// // // // // // //       if (await downloadedFile.exists()) {
// // // // // // //         final fileSize = await downloadedFile.length();
// // // // // // //         debugPrint('[OTA] Tải thành công! Kích thước: $fileSize bytes');

// // // // // // //         if (fileSize > 50000) {
// // // // // // //           localDownloadedBinPath = filePath;

// // // // // // //           // Chỉ quét MediaScanner trên Android
// // // // // // //           if (Platform.isAndroid) {
// // // // // // //             try {
// // // // // // //               await MediaScanner.loadMedia(path: filePath);
// // // // // // //             } catch (e) {
// // // // // // //               debugPrint('[OTA] Lỗi MediaScanner Android: $e');
// // // // // // //             }
// // // // // // //           }

// // // // // // //           return filePath;
// // // // // // //         } else {
// // // // // // //           await downloadedFile.delete();
// // // // // // //           throw Exception("File tải về quá nhỏ ($fileSize bytes).");
// // // // // // //         }
// // // // // // //       } else {
// // // // // // //         throw Exception("Không thể tạo file tại đường dẫn chỉ định.");
// // // // // // //       }

// // // // // // //     } catch (e) {
// // // // // // //       debugPrint('[OTA] Lỗi tải file Firmware: $e');
// // // // // // //       return null;
// // // // // // //     }
// // // // // // //   }
// // // // // // // }

// // // // // // import 'dart:io';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:path_provider/path_provider.dart';
// // // // // // import 'package:dio/dio.dart';
// // // // // // import 'package:permission_handler/permission_handler.dart';

// // // // // // class FirmwareService {
// // // // // //   static String? localDownloadedBinPath;

// // // // // //   // 🟢 Lấy thư mục lưu trữ khả dụng công khai
// // // // // //   static Future<Directory> getSavedBinFolder() async {
// // // // // //     if (Platform.isAndroid) {
// // // // // //       // 1. Ưu tiên thư mục Download/bin_esp32 công khai
// // // // // //       final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
      
// // // // // //       try {
// // // // // //         if (!await publicDownloadDir.exists()) {
// // // // // //           await publicDownloadDir.create(recursive: true);
// // // // // //         }
// // // // // //         return publicDownloadDir;
// // // // // //       } catch (_) {
// // // // // //         // 2. Fallback sang thư mục Download gốc
// // // // // //         final generalDownloadDir = Directory('/storage/emulated/0/Download');
// // // // // //         if (await generalDownloadDir.exists()) {
// // // // // //           return generalDownloadDir;
// // // // // //         }
// // // // // //         // 3. Fallback cuối cùng
// // // // // //         final extDir = await getExternalStorageDirectory();
// // // // // //         return Directory('${extDir?.path}/bin_esp32');
// // // // // //       }
// // // // // //     } else {
// // // // // //       final docsDir = await getApplicationDocumentsDirectory();
// // // // // //       return Directory('${docsDir.path}/bin_esp32');
// // // // // //     }
// // // // // //   }

// // // // // //   // 🟢 Lấy file .bin mới nhất
// // // // // //   static Future<File?> getLatestDownloadedBinFile() async {
// // // // // //     final folder = await getSavedBinFolder();
// // // // // //     if (await folder.exists()) {
// // // // // //       final files = folder
// // // // // //           .listSync()
// // // // // //           .whereType<File>()
// // // // // //           .where((f) => f.path.endsWith('.bin'))
// // // // // //           .toList();
// // // // // //       if (files.isNotEmpty) {
// // // // // //         files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
// // // // // //         return files.first;
// // // // // //       }
// // // // // //     }
// // // // // //     return null;
// // // // // //   }

// // // // // //   /// Tải file .bin về điện thoại
// // // // // //   static Future<String?> downloadToBinFolder(
// // // // // //     String downloadUrl, {
// // // // // //     String? version,
// // // // // //     void Function(int received, int total)? onProgress,
// // // // // //   }) async {
// // // // // //     try {
// // // // // //       // 🟢 1. Xin quyền bộ nhớ trên Android (Đặc biệt Android 11 trở xuống)
// // // // // //       if (Platform.isAndroid) {
// // // // // //         await Permission.storage.request();
// // // // // //       }

// // // // // //       Directory customFolder = await getSavedBinFolder();

// // // // // //       // 🟢 2. Xóa các file .bin cũ trong thư mục trước khi tải file mới
// // // // // //       if (await customFolder.exists()) {
// // // // // //         try {
// // // // // //           final files = customFolder.listSync();
// // // // // //           for (var file in files) {
// // // // // //             if (file.path.endsWith('.bin')) {
// // // // // //               await file.delete();
// // // // // //             }
// // // // // //           }
// // // // // //         } catch (e) {
// // // // // //           debugPrint('[OTA] Không thể xóa file cũ: $e');
// // // // // //         }
// // // // // //       }

// // // // // //       // Đặt tên file ngắn gọn, loại bỏ ký tự lạ
// // // // // //       final fileName = version != null ? 'firmware_v$version.bin' : 'firmware_latest.bin';
// // // // // //       final filePath = '${customFolder.path}/$fileName';

// // // // // //       debugPrint('[OTA] Đường dẫn lưu file thực tế: $filePath');

// // // // // //       // 🟢 3. Cấu hình Dio tải file (Hỗ trợ Redirect GitHub 302)
// // // // // //       final dio = Dio();
// // // // // //       await dio.download(
// // // // // //         downloadUrl,
// // // // // //         filePath,
// // // // // //         onReceiveProgress: (received, total) {
// // // // // //           if (onProgress != null) {
// // // // // //             onProgress(received, total);
// // // // // //           }
// // // // // //         },
// // // // // //         options: Options(
// // // // // //           responseType: ResponseType.bytes,
// // // // // //           followRedirects: true,
// // // // // //           maxRedirects: 10,
// // // // // //           headers: {
// // // // // //             'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
// // // // // //           },
// // // // // //         ),
// // // // // //       );

// // // // // //       final downloadedFile = File(filePath);
// // // // // //       if (await downloadedFile.exists()) {
// // // // // //         final fileSize = await downloadedFile.length();
// // // // // //         debugPrint('[OTA] Tải thành công! Dung lượng: $fileSize bytes');

// // // // // //         if (fileSize > 50000) { // File lớn hơn 50KB mới hợp lệ
// // // // // //           localDownloadedBinPath = filePath;
// // // // // //           return filePath;
// // // // // //         } else {
// // // // // //           await downloadedFile.delete();
// // // // // //           throw Exception("File tải về quá nhỏ ($fileSize bytes) - Có thể link URL bị lỗi HTML 404/302.");
// // // // // //         }
// // // // // //       } else {
// // // // // //         throw Exception("Không thể tạo file tại đường dẫn: $filePath");
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       debugPrint('[OTA] Lỗi tải file Firmware: $e');
// // // // // //       return null;
// // // // // //     }
// // // // // //   }
// // // // // // }
// // // // // import 'dart:io';
// // // // // import 'package:dio/dio.dart';
// // // // // import 'package:path_provider/path_provider.dart';
// // // // // import 'package:permission_handler/permission_handler.dart';

// // // // // class FirmwareService {
// // // // //   static String? localDownloadedBinPath;

// // // // //   static Future<String> downloadToBinFolder(
// // // // //     String url, {
// // // // //     String? version,
// // // // //     Function(int received, int total)? onProgress,
// // // // //   }) async {
// // // // //     // 1. Xin quyền bộ nhớ (Dành cho Android)
// // // // //     if (Platform.isAndroid) {
// // // // //       await Permission.storage.request();
// // // // //       await Permission.manageExternalStorage.request();
// // // // //     }

// // // // //     // 2. Xác định thư mục lưu trữ thực tế
// // // // //     Directory? targetDir;

// // // // //     if (Platform.isAndroid) {
// // // // //       // 🟢 Ép buộc lấy đúng đường dẫn thư mục Download công khai của máy
// // // // //       final downloadDir = Directory('/storage/emulated/0/Download');
// // // // //       if (await downloadDir.exists()) {
// // // // //         targetDir = Directory('${downloadDir.path}/bin_esp32');
// // // // //       } else {
// // // // //         // Dự phòng nếu máy không theo chuẩn /storage/emulated/0
// // // // //         final extDir = await getExternalStorageDirectory();
// // // // //         targetDir = Directory('${extDir?.path}/bin_esp32');
// // // // //       }
// // // // //     } else {
// // // // //       // Dành cho iOS / iPadOS
// // // // //       final docDir = await getApplicationDocumentsDirectory();
// // // // //       targetDir = Directory('${docDir.path}/bin_esp32');
// // // // //     }

// // // // //     // 3. Tạo thư mục bin_esp32 nếu chưa có
// // // // //     if (!await targetDir.exists()) {
// // // // //       await targetDir.create(recursive: true);
// // // // //     }

// // // // //     // 4. Đặt tên file theo phiên bản
// // // // //     final fileName = version != null && version.isNotEmpty
// // // // //         ? 'firmware_v$version.bin'
// // // // //         : 'firmware_latest.bin';

// // // // //     final savePath = '${targetDir.path}/$fileName';

// // // // //     // 5. Tiến hành tải bằng Dio
// // // // //     final dio = Dio();
// // // // //     await dio.download(
// // // // //       url,
// // // // //       savePath,
// // // // //       onReceiveProgress: onProgress,
// // // // //     );

// // // // //     // Lưu lại đường dẫn file vừa tải vào biến tạm
// // // // //     localDownloadedBinPath = savePath;
// // // // //     return savePath;
// // // // //   }

// // // // //   // Hàm hỗ trợ tìm file .bin mới nhất trong máy
// // // // //   static Future<File?> getLatestDownloadedBinFile() async {
// // // // //     try {
// // // // //       Directory? targetDir;
// // // // //       if (Platform.isAndroid) {
// // // // //         final downloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // // //         if (await downloadDir.exists()) {
// // // // //           targetDir = downloadDir;
// // // // //         }
// // // // //       }
      
// // // // //       if (targetDir == null || !await targetDir.exists()) {
// // // // //         if (localDownloadedBinPath != null) {
// // // // //           final file = File(localDownloadedBinPath!);
// // // // //           if (await file.exists()) return file;
// // // // //         }
// // // // //         return null;
// // // // //       }

// // // // //       final files = targetDir
// // // // //           .listSync()
// // // // //           .whereType<File>()
// // // // //           .where((f) => f.path.endsWith('.bin'))
// // // // //           .toList();

// // // // //       if (files.isEmpty) return null;

// // // // //       // Sắp xếp lấy file mới tải gần nhất
// // // // //       files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
// // // // //       return files.first;
// // // // //     } catch (e) {
// // // // //       return null;
// // // // //     }
// // // // //   }
// // // // // }

// // // // import 'dart:io';
// // // // import 'package:dio/dio.dart';
// // // // import 'package:path_provider/path_provider.dart';

// // // // class FirmwareService {
// // // //   static String? localDownloadedBinPath;

// // // //   static Future<String> downloadToBinFolder(
// // // //     String url, {
// // // //     String? version,
// // // //     Function(int received, int total)? onProgress,
// // // //   }) async {
// // // //     Directory? targetDir;

// // // //     if (Platform.isAndroid) {
// // // //       // 🟢 1. Trỏ trực tiếp vào thư mục Download công khai của Android
// // // //       final publicDownloadDir = Directory('/storage/emulated/0/Download');
      
// // // //       if (await publicDownloadDir.exists()) {
// // // //         targetDir = Directory('${publicDownloadDir.path}/bin_esp32');
// // // //       } else {
// // // //         // Dự phòng cho một số dòng máy Android đời cũ
// // // //         final extDir = await getExternalStorageDirectory();
// // // //         targetDir = Directory('${extDir?.path}/bin_esp32');
// // // //       }
// // // //     } else {
// // // //       // Dành cho iOS / iPadOS
// // // //       final docDir = await getApplicationDocumentsDirectory();
// // // //       targetDir = Directory('${docDir.path}/bin_esp32');
// // // //     }

// // // //     // 🟢 2. Tự động tạo thư mục bin_esp32 nếu chưa có
// // // //     if (!await targetDir.exists()) {
// // // //       await targetDir.create(recursive: true);
// // // //     }

// // // //     // 3. Đặt tên file .bin
// // // //     final fileName = version != null && version.isNotEmpty
// // // //         ? 'firmware_v$version.bin'
// // // //         : 'firmware_latest.bin';

// // // //     final savePath = '${targetDir.path}/$fileName';

// // // //     // 🟢 4. Tải và ghi trực tiếp vào thư mục mà không hỏi người dùng
// // // //     final dio = Dio();
// // // //     await dio.download(
// // // //       url,
// // // //       savePath,
// // // //       onReceiveProgress: onProgress,
// // // //     );

// // // //     localDownloadedBinPath = savePath;
// // // //     return savePath;
// // // //   }

// // // //   // Hàm quét tìm file .bin mới nhất trong máy
// // // //   static Future<File?> getLatestDownloadedBinFile() async {
// // // //     try {
// // // //       Directory? targetDir;
// // // //       if (Platform.isAndroid) {
// // // //         final downloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
// // // //         if (await downloadDir.exists()) {
// // // //           targetDir = downloadDir;
// // // //         }
// // // //       }

// // // //       if (targetDir == null || !await targetDir.exists()) {
// // // //         if (localDownloadedBinPath != null) {
// // // //           final file = File(localDownloadedBinPath!);
// // // //           if (await file.exists()) return file;
// // // //         }
// // // //         return null;
// // // //       }

// // // //       final files = targetDir
// // // //           .listSync()
// // // //           .whereType<File>()
// // // //           .where((f) => f.path.endsWith('.bin'))
// // // //           .toList();

// // // //       if (files.isEmpty) return null;

// // // //       files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
// // // //       return files.first;
// // // //     } catch (e) {
// // // //       return null;
// // // //     }
// // // //   }
// // // // }
// // // import 'dart:io';
// // // import 'package:dio/dio.dart';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:path_provider/path_provider.dart';

// // // class FirmwareService {
// // //   // Biến lưu tạm đường dẫn file .bin vừa tải gần nhất
// // //   static String? localDownloadedBinPath;

// // //   // 🟢 HÀM 1: LẤY FILE .BIN MỚI NHẤT TRONG THƯ MỤC LƯU TRỮ (CÓ DEBUGPRINT)
// // //   static Future<File?> getLatestDownloadedBinFile() async {
// // //     debugPrint('--------------------------------------------------');
// // //     debugPrint('[FirmwareService Debug] Bắt đầu tìm file .bin mới nhất...');

// // //     try {
// // //       Directory? targetDir;

// // //       if (Platform.isAndroid) {
// // //         final downloadsDir = Directory('/storage/emulated/0/Download');
// // //         if (await downloadsDir.exists()) {
// // //           targetDir = Directory('${downloadsDir.path}/bin_esp32');
// // //           debugPrint('[FirmwareService Debug] HĐH Android: Trỏ vào thư mục ${targetDir.path}');
// // //         } else {
// // //           final extDir = await getExternalStorageDirectory();
// // //           targetDir = Directory('${extDir?.path}/bin_esp32');
// // //           debugPrint('[FirmwareService Debug] HĐH Android (Fallback App Storage): Trỏ vào thư mục ${targetDir.path}');
// // //         }
// // //       } else if (Platform.isIOS) {
// // //         final docsDir = await getApplicationDocumentsDirectory();
// // //         targetDir = Directory('${docsDir.path}/bin_esp32');
// // //         debugPrint('[FirmwareService Debug] HĐH iOS: Trỏ vào thư mục ${targetDir.path}');
// // //       }

// // //       if (targetDir == null || !await targetDir.exists()) {
// // //         debugPrint('[FirmwareService Debug] ⚠️ Thư mục targetDir chưa tồn tại hoặc bằng null!');
// // //         debugPrint('--------------------------------------------------');
// // //         return null;
// // //       }

// // //       // Quét tất cả các file có đuôi .bin trong thư mục
// // //       final List<FileSystemEntity> entities = await targetDir.list().toList();
// // //       final List<File> binFiles = entities
// // //           .whereType<File>()
// // //           .where((file) => file.path.endsWith('.bin'))
// // //           .toList();

// // //       debugPrint('[FirmwareService Debug] Tìm thấy ${binFiles.length} file .bin trong thư mục.');

// // //       if (binFiles.isEmpty) {
// // //         debugPrint('[FirmwareService Debug] ⚠️ Không có file .bin nào trong thư mục!');
// // //         debugPrint('--------------------------------------------------');
// // //         return null;
// // //       }

// // //       // Sắp xếp lấy file được sửa đổi/tải về gần nhất
// // //       binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
// // //       final latestFile = binFiles.first;
// // //       debugPrint('[FirmwareService Debug] ✅ File .bin mới nhất được chọn: ${latestFile.path}');
// // //       debugPrint('[FirmwareService Debug] 🕒 Thời gian tạo/sửa đổi: ${latestFile.lastModifiedSync()}');
// // //       debugPrint('--------------------------------------------------');

// // //       return latestFile;
// // //     } catch (e) {
// // //       debugPrint('[FirmwareService Debug] ❌ Lỗi khi quét tìm file .bin: $e');
// // //       debugPrint('--------------------------------------------------');
// // //       return null;
// // //     }
// // //   }

// // //   // 🟢 HÀM 2: TẢI FILE FIRMWARE VỀ MÁY VÀ TẠO THƯ MỤC AN TOÀN (CÓ DEBUGPRINT)
// // //   static Future<String> downloadToBinFolder(
// // //   String url, {
// // //   String? version,
// // //   Function(int received, int total)? onProgress,
// // // }) async {
// // //   debugPrint('--------------------------------------------------');
// // //   debugPrint('[FirmwareService Debug] 🚀 Bắt đầu quá trình tải Firmware...');
// // //   debugPrint('[FirmwareService Debug] Link URL: $url');
// // //   debugPrint('[FirmwareService Debug] Version: ${version ?? "Tự động (Latest)"}');

// // //   Directory? targetDir;

// // //   if (Platform.isAndroid) {
// // //     final downloadsDir = Directory('/storage/emulated/0/Download');
// // //     if (await downloadsDir.exists()) {
// // //       targetDir = Directory('${downloadsDir.path}/bin_esp32');
// // //     } else {
// // //       final extDir = await getExternalStorageDirectory();
// // //       targetDir = Directory('${extDir?.path}/bin_esp32');
// // //     }
// // //   } else if (Platform.isIOS) {
// // //     final docsDir = await getApplicationDocumentsDirectory();
// // //     targetDir = Directory('${docsDir.path}/bin_esp32');
// // //   }

// // //   // 🟢 QUAN TRỌNG: Đảm bảo tạo thư mục thành công trước khi ghi file
// // //   if (targetDir != null && !await targetDir.exists()) {
// // //     debugPrint('[FirmwareService Debug] Thư mục chưa tồn tại, tiến hành tạo thư mục: ${targetDir.path}');
// // //     await targetDir.create(recursive: true);
// // //     debugPrint('[FirmwareService Debug] ✅ Tạo thư mục thành công!');
// // //   }

// // //   final fileName = version != null && version.isNotEmpty
// // //       ? 'firmware_v$version.bin'
// // //       : 'firmware_latest.bin';

// // //   final savePath = '${targetDir!.path}/$fileName';
// // //   final file = File(savePath);

// // //   debugPrint('[FirmwareService Debug] Đích đến lưu file: $savePath');

// // //   // Xóa file cũ nếu đã tồn tại
// // //   if (await file.exists()) {
// // //     debugPrint('[FirmwareService Debug] File đã tồn tại, xóa file cũ để ghi đè...');
// // //     await file.delete();
// // //   }

// // //   // 🟢 TỐI ƯU DIO CHO LINK GITHUB RELEASES REDIRECT
// // //   final dio = Dio(
// // //     BaseOptions(
// // //       connectTimeout: const Duration(seconds: 15),
// // //       receiveTimeout: const Duration(minutes: 2),
// // //       followRedirects: true,
// // //       maxRedirects: 5,
// // //       validateStatus: (status) => status != null && status < 500,
// // //     ),
// // //   );

// // //   await dio.download(
// // //     url,
// // //     savePath,
// // //     onReceiveProgress: (received, total) {
// // //       if (total != -1) {
// // //         final percentage = (received / total * 100).toStringAsFixed(0);
// // //         debugPrint('[FirmwareService Debug] Tiến trình tải: $percentage% ($received / $total bytes)');
// // //       } else {
// // //         debugPrint('[FirmwareService Debug] Đang nhận dữ liệu: $received bytes...');
// // //       }
// // //       if (onProgress != null) {
// // //         onProgress(received, total);
// // //       }
// // //     },
// // //   );

// // //   debugPrint('[FirmwareService Debug] 🎉 Tải thành công Firmware lưu tại: $savePath');
// // //   debugPrint('--------------------------------------------------');

// // //   localDownloadedBinPath = savePath;
// // //   return savePath;
// // // }
// // // }
// // import 'dart:io';
// // import 'package:dio/dio.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:path_provider/path_provider.dart';

// // class FirmwareService {
// //   static String? localDownloadedBinPath;

// //   // 🟢 HÀM 1: LẤY FILE .BIN MỚI NHẤT
// //   static Future<File?> getLatestDownloadedBinFile() async {
// //     debugPrint('--------------------------------------------------');
// //     debugPrint('[FirmwareService Debug] Bắt đầu tìm file .bin mới nhất...');

// //     try {
// //       Directory? targetDir;

// //       if (Platform.isAndroid) {
// //         final downloadsDir = Directory('/storage/emulated/0/Download');
// //         if (await downloadsDir.exists()) {
// //           targetDir = Directory('${downloadsDir.path}/bin_esp32');
// //         } else {
// //           final extDir = await getExternalStorageDirectory();
// //           targetDir = Directory('${extDir?.path}/bin_esp32');
// //         }
// //       } else if (Platform.isIOS) {
// //         final docsDir = await getApplicationDocumentsDirectory();
// //         targetDir = Directory('${docsDir.path}/bin_esp32');
// //       }

// //       if (targetDir == null || !await targetDir.exists()) {
// //         debugPrint('[FirmwareService Debug] ⚠️ Thư mục chưa tồn tại!');
// //         return null;
// //       }

// //       final List<FileSystemEntity> entities = await targetDir.list().toList();
// //       final List<File> binFiles = entities
// //           .whereType<File>()
// //           .where((file) => file.path.endsWith('.bin'))
// //           .toList();

// //       debugPrint('[FirmwareService Debug] Tìm thấy ${binFiles.length} file .bin');

// //       if (binFiles.isEmpty) return null;

// //       binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
// //       final latestFile = binFiles.first;
      
// //       debugPrint('[FirmwareService Debug] ✅ File chọn: ${latestFile.path}');
// //       return latestFile;
// //     } catch (e) {
// //       debugPrint('[FirmwareService Debug] ❌ Lỗi quét file: $e');
// //       return null;
// //     }
// //   }

// //   // 🟢 HÀM 2: TẢI FILE FIRMWARE VỀ MÁY (KHẮC PHỤC TREO XÓA FILE)
// //   // static Future<String> downloadToBinFolder(
// //   //   String url, {
// //   //   String? version,
// //   //   Function(int received, int total)? onProgress,
// //   // }) async {
// //   //   debugPrint('--------------------------------------------------');
// //   //   debugPrint('[FirmwareService Debug] 🚀 Bắt đầu quá trình tải Firmware...');
// //   //   debugPrint('[FirmwareService Debug] Link URL: $url');
// //   //   debugPrint('[FirmwareService Debug] Version: ${version ?? "Latest"}');

// //   //   Directory? targetDir;

// //   //   if (Platform.isAndroid) {
// //   //     final downloadsDir = Directory('/storage/emulated/0/Download');
// //   //     if (await downloadsDir.exists()) {
// //   //       targetDir = Directory('${downloadsDir.path}/bin_esp32');
// //   //     } else {
// //   //       final extDir = await getExternalStorageDirectory();
// //   //       targetDir = Directory('${extDir?.path}/bin_esp32');
// //   //     }
// //   //   } else if (Platform.isIOS) {
// //   //     final docsDir = await getApplicationDocumentsDirectory();
// //   //     targetDir = Directory('${docsDir.path}/bin_esp32');
// //   //   }

// //   //   if (targetDir != null && !await targetDir.exists()) {
// //   //     debugPrint('[FirmwareService Debug] Tạo thư mục: ${targetDir.path}');
// //   //     await targetDir.create(recursive: true);
// //   //   }

// //   //   final fileName = version != null && version.isNotEmpty
// //   //       ? 'firmware_v$version.bin'
// //   //       : 'firmware_latest.bin';

// //   //   final savePath = '${targetDir!.path}/$fileName';
// //   //   final file = File(savePath);

// //   //   debugPrint('[FirmwareService Debug] Đích đến lưu file: $savePath');

// //   //   // 🟢 AN TOÀN: Xử lý xóa file cũ trong try-catch, tránh đứng hình app
// //   //   if (await file.exists()) {
// //   //     try {
// //   //       debugPrint('[FirmwareService Debug] Thử xóa file cũ...');
// //   //       await file.delete();
// //   //       debugPrint('[FirmwareService Debug] Đã xóa file cũ thành công.');
// //   //     } catch (e) {
// //   //       debugPrint('[FirmwareService Debug] ⚠️ Không thể xóa file cũ ($e), sẽ ghi đè trực tiếp.');
// //   //     }
// //   //   }

// //   //   // 🟢 TỐI ƯU DIO CHO GITHUB RELEASES (CÓ USER-AGENT VÀ CƠ CHẾ KHÔNG KHỰNG)
// //   //   final dio = Dio(
// //   //     BaseOptions(
// //   //       headers: {
// //   //         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
// //   //         'Accept': '*/*',
// //   //       },
// //   //       connectTimeout: const Duration(seconds: 20),
// //   //       receiveTimeout: const Duration(minutes: 3),
// //   //       followRedirects: true,
// //   //       maxRedirects: 8,
// //   //     ),
// //   //   );

// //   //   debugPrint('[FirmwareService Debug] 📡 Đang gửi request tải file từ Server...');

// //   //   await dio.download(
// //   //     url,
// //   //     savePath,
// //   //     onReceiveProgress: (received, total) {
// //   //       if (total != -1) {
// //   //         final percentage = (received / total * 100).toStringAsFixed(0);
// //   //         debugPrint('[FirmwareService Debug] Tiến trình: $percentage% ($received / $total bytes)');
// //   //       } else {
// //   //         debugPrint('[FirmwareService Debug] Đang nhận dữ liệu: $received bytes...');
// //   //       }
// //   //       if (onProgress != null) {
// //   //         onProgress(received, total);
// //   //       }
// //   //     },
// //   //     deleteOnError: true,
// //   //   );

// //   //   debugPrint('[FirmwareService Debug] 🎉 Tải thành công Firmware lưu tại: $savePath');
// //   //   debugPrint('--------------------------------------------------');

// //   //   localDownloadedBinPath = savePath;
// //   //   return savePath;
// //   // }
// //   static Future<String> downloadToBinFolder(
// //   String url, {
// //   String? version,
// //   Function(int received, int total)? onProgress,
// // }) async {
// //   Directory? targetDir;

// //   if (Platform.isAndroid) {
// //     final downloadsDir = Directory('/storage/emulated/0/Download');
// //     if (await downloadsDir.exists()) {
// //       targetDir = Directory('${downloadsDir.path}/bin_esp32');
// //     } else {
// //       final extDir = await getExternalStorageDirectory();
// //       targetDir = Directory('${extDir?.path}/bin_esp32');
// //     }
// //   } else if (Platform.isIOS) {
// //     final docsDir = await getApplicationDocumentsDirectory();
// //     targetDir = Directory('${docsDir.path}/bin_esp32');
// //   }

// //   if (targetDir != null && !await targetDir.exists()) {
// //     await targetDir.create(recursive: true);
// //   }

// //   // 🟢 1. LẤY NGUYÊN TÊN FILE GỐC TỪ CẦU TRÚC URL TRÊN GITHUB RELEASE
// //   // Ví dụ: URL kết thúc bằng 'v1.0.16.bin' -> fileName sẽ là 'v1.0.16.bin'
// //   String fileName = url.split('/').last.split('?').first;

// //   // Trường hợp dự phòng nếu URL không chứa đuôi .bin
// //   if (!fileName.endsWith('.bin')) {
// //     fileName = version != null ? 'v$version.bin' : 'firmware.bin';
// //   }

// //   final savePath = '${targetDir!.path}/$fileName';
// //   final file = File(savePath);

// //   debugPrint('[FirmwareService] Giữ nguyên tên file gốc từ GitHub: $fileName');
// //   debugPrint('[FirmwareService] Đường dẫn lưu file: $savePath');

// //   if (await file.exists()) {
// //     try {
// //       await file.delete();
// //     } catch (_) {}
// //   }

// //   final dio = Dio(
// //     BaseOptions(
// //       headers: {
// //         'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
// //         'Accept': '*/*',
// //       },
// //       connectTimeout: const Duration(seconds: 20),
// //       receiveTimeout: const Duration(minutes: 3),
// //       followRedirects: true,
// //       maxRedirects: 8,
// //     ),
// //   );

// //   await dio.download(
// //     url,
// //     savePath,
// //     onReceiveProgress: onProgress,
// //     deleteOnError: true,
// //   );

// //   localDownloadedBinPath = savePath;
// //   return savePath;
// // }
// // }

// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';

// class FirmwareService {
//   // Biến lưu tạm đường dẫn file .bin vừa tải gần nhất
//   static String? localDownloadedBinPath;

//   // 🟢 HÀM 1: LẤY FILE .BIN MỚI NHẤT TRONG THƯ MỤC LƯU TRỮ
//   static Future<File?> getLatestDownloadedBinFile() async {
//     debugPrint('--------------------------------------------------');
//     debugPrint('[FirmwareService Debug] 🔍 Bắt đầu quét tìm file .bin mới nhất...');

//     try {
//       Directory? targetDir;

//       if (Platform.isAndroid) {
//         final downloadsDir = Directory('/storage/emulated/0/Download');
//         if (await downloadsDir.exists()) {
//           targetDir = Directory('${downloadsDir.path}/bin_esp32');
//           debugPrint('[FirmwareService Debug] HĐH Android: Trỏ vào thư mục ${targetDir.path}');
//         } else {
//           final extDir = await getExternalStorageDirectory();
//           targetDir = Directory('${extDir?.path}/bin_esp32');
//           debugPrint('[FirmwareService Debug] HĐH Android (Fallback): Trỏ vào thư mục ${targetDir.path}');
//         }
//       } else if (Platform.isIOS) {
//         final docsDir = await getApplicationDocumentsDirectory();
//         targetDir = Directory('${docsDir.path}/bin_esp32');
//         debugPrint('[FirmwareService Debug] HĐH iOS: Trỏ vào thư mục ${targetDir.path}');
//       }

//       if (targetDir == null || !await targetDir.exists()) {
//         debugPrint('[FirmwareService Debug] ⚠️ Thư mục chưa tồn tại hoặc targetDir null!');
//         debugPrint('--------------------------------------------------');
//         return null;
//       }

//       final List<FileSystemEntity> entities = await targetDir.list().toList();
//       final List<File> binFiles = entities
//           .whereType<File>()
//           .where((file) => file.path.endsWith('.bin'))
//           .toList();

//       debugPrint('[FirmwareService Debug] Tìm thấy ${binFiles.length} file .bin trong thư mục.');

//       if (binFiles.isEmpty) {
//         debugPrint('[FirmwareService Debug] ⚠️ Không có file .bin nào trong thư mục!');
//         debugPrint('--------------------------------------------------');
//         return null;
//       }

//       // Sắp xếp lấy file được sửa đổi/tải về gần nhất
//       binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
//       final latestFile = binFiles.first;

//       debugPrint('[FirmwareService Debug] ✅ File chọn: ${latestFile.path}');
//       debugPrint('[FirmwareService Debug] 🕒 Thời gian sửa đổi: ${latestFile.lastModifiedSync()}');
//       debugPrint('--------------------------------------------------');

//       return latestFile;
//     } catch (e) {
//       debugPrint('[FirmwareService Debug] ❌ Lỗi quét file: $e');
//       debugPrint('--------------------------------------------------');
//       return null;
//     }
//   }

//   // 🟢 HÀM 2: TẢI FILE FIRMWARE - GIỮ NGUYÊN TÊN GỐC TỪ GITHUB & LOG DEBUG CHI TIẾT
//   static Future<String> downloadToBinFolder(
//     String url, {
//     String? version,
//     Function(int received, int total)? onProgress,
//   }) async {
//     debugPrint('--------------------------------------------------');
//     debugPrint('[FirmwareService Debug] 🚀 Bắt đầu quá trình tải Firmware...');
//     debugPrint('[FirmwareService Debug] URL tải về: $url');
//     debugPrint('[FirmwareService Debug] Version nhận từ Remote/API: ${version ?? "Không chỉ định"}');

//     Directory? targetDir;

//     if (Platform.isAndroid) {
//       final downloadsDir = Directory('/storage/emulated/0/Download');
//       if (await downloadsDir.exists()) {
//         targetDir = Directory('${downloadsDir.path}/bin_esp32');
//       } else {
//         final extDir = await getExternalStorageDirectory();
//         targetDir = Directory('${extDir?.path}/bin_esp32');
//       }
//     } else if (Platform.isIOS) {
//       final docsDir = await getApplicationDocumentsDirectory();
//       targetDir = Directory('${docsDir.path}/bin_esp32');
//     }

//     // Tạo thư mục nếu chưa tồn tại
//     if (targetDir != null && !await targetDir.exists()) {
//       debugPrint('[FirmwareService Debug] Tạo thư mục lưu trữ: ${targetDir.path}');
//       await targetDir.create(recursive: true);
//       debugPrint('[FirmwareService Debug] ✅ Tạo thư mục thành công!');
//     }

//     // 🟢 LẤY NGUYÊN TÊN FILE GỐC TỪ CẤU TRÚC URL TRÊN GITHUB RELEASE
//     // Ví dụ URL: .../releases/download/v1.0.0-assets/v1.0.16.bin -> fileName: 'v1.0.16.bin'
//     String fileName = url.split('/').last.split('?').first;
//     debugPrint('[FirmwareService Debug] Tên file trích xuất từ URL: "$fileName"');

//     // Trường hợp dự phòng nếu URL không có đuôi .bin
//     if (!fileName.endsWith('.bin')) {
//       fileName = version != null ? 'v$version.bin' : 'firmware.bin';
//       debugPrint('[FirmwareService Debug] ⚠️ URL không chứa đuôi .bin, chuyển sang tên dự phòng: "$fileName"');
//     }

//     final savePath = '${targetDir!.path}/$fileName';
//     final file = File(savePath);

//     debugPrint('[FirmwareService Debug] Đích đến lưu file trên máy: $savePath');

//     // Xử lý xóa file cũ trùng tên an toàn
//     if (await file.exists()) {
//       try {
//         debugPrint('[FirmwareService Debug] Phát hiện file cũ trùng tên, tiến hành xóa...');
//         await file.delete();
//         debugPrint('[FirmwareService Debug] ✅ Đã xóa file cũ thành công.');
//       } catch (e) {
//         debugPrint('[FirmwareService Debug] ⚠️ Không thể xóa file cũ ($e), sẽ ghi đè trực tiếp.');
//       }
//     }

//     // Cấu hình Dio tối ưu cho Redirect của GitHub Releases
//     final dio = Dio(
//       BaseOptions(
//         headers: {
//           'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
//           'Accept': '*/*',
//         },
//         connectTimeout: const Duration(seconds: 20),
//         receiveTimeout: const Duration(minutes: 3),
//         followRedirects: true,
//         maxRedirects: 8,
//       ),
//     );

//     debugPrint('[FirmwareService Debug] 📡 Đang kết nối Server và nhận stream dữ liệu...');

//     await dio.download(
//       url,
//       savePath,
//       onReceiveProgress: (received, total) {
//         if (total != -1) {
//           final percentage = (received / total * 100).toStringAsFixed(0);
//           debugPrint('[FirmwareService Debug] Tiến trình tải: $percentage% ($received / $total bytes)');
//         } else {
//           debugPrint('[FirmwareService Debug] Đang nhận dữ liệu: $received bytes...');
//         }
//         if (onProgress != null) {
//           onProgress(received, total);
//         }
//       },
//       deleteOnError: true,
//     );

//     debugPrint('[FirmwareService Debug] 🎉 Tải thành công Firmware giữ nguyên tên gốc!');
//     debugPrint('[FirmwareService Debug] File lưu tại: $savePath');
//     debugPrint('--------------------------------------------------');

//     localDownloadedBinPath = savePath;
//     return savePath;
//   }
// }
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:media_scanner/media_scanner.dart'; // 🟢 1. THÊM IMPORT NÀY
import 'package:path_provider/path_provider.dart';

class FirmwareService {
  // Biến lưu tạm đường dẫn file .bin vừa tải gần nhất
  static String? localDownloadedBinPath;

  // 🟢 HÀM 1: LẤY FILE .BIN MỚI NHẤT TRONG THƯ MỤC LƯU TRỮ
  static Future<File?> getLatestDownloadedBinFile() async {
    debugPrint('--------------------------------------------------');
    debugPrint('[FirmwareService Debug] 🔍 Bắt đầu quét tìm file .bin mới nhất...');

    try {
      Directory? targetDir;

      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          targetDir = Directory('${downloadsDir.path}/bin_esp32');
          debugPrint('[FirmwareService Debug] HĐH Android: Trỏ vào thư mục ${targetDir.path}');
        } else {
          final extDir = await getExternalStorageDirectory();
          targetDir = Directory('${extDir?.path}/bin_esp32');
          debugPrint('[FirmwareService Debug] HĐH Android (Fallback): Trỏ vào thư mục ${targetDir.path}');
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docsDir.path}/bin_esp32');
        debugPrint('[FirmwareService Debug] HĐH iOS: Trỏ vào thư mục ${targetDir.path}');
      }

      if (targetDir == null || !await targetDir.exists()) {
        debugPrint('[FirmwareService Debug] ⚠️ Thư mục chưa tồn tại hoặc targetDir null!');
        debugPrint('--------------------------------------------------');
        return null;
      }

      final List<FileSystemEntity> entities = await targetDir.list().toList();
      final List<File> binFiles = entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.bin'))
          .toList();

      debugPrint('[FirmwareService Debug] Tìm thấy ${binFiles.length} file .bin trong thư mục.');

      if (binFiles.isEmpty) {
        debugPrint('[FirmwareService Debug] ⚠️ Không có file .bin nào trong thư mục!');
        debugPrint('--------------------------------------------------');
        return null;
      }

      // Sắp xếp lấy file được sửa đổi/tải về gần nhất
      binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestFile = binFiles.first;

      debugPrint('[FirmwareService Debug] ✅ File chọn: ${latestFile.path}');
      debugPrint('[FirmwareService Debug] 🕒 Thời gian sửa đổi: ${latestFile.lastModifiedSync()}');
      debugPrint('--------------------------------------------------');

      return latestFile;
    } catch (e) {
      debugPrint('[FirmwareService Debug] ❌ Lỗi quét file: $e');
      debugPrint('--------------------------------------------------');
      return null;
    }
  }

  // 🟢 HÀM 2: TẢI FILE FIRMWARE - GIỮ NGUYÊN TÊN GỐC TỪ GITHUB & LOG DEBUG CHI TIẾT
  static Future<String> downloadToBinFolder(
    String url, {
    String? version,
    Function(int received, int total)? onProgress,
  }) async {
    debugPrint('--------------------------------------------------');
    debugPrint('[FirmwareService Debug] 🚀 Bắt đầu quá trình tải Firmware...');
    debugPrint('[FirmwareService Debug] URL tải về: $url');
    debugPrint('[FirmwareService Debug] Version nhận từ Remote/API: ${version ?? "Không chỉ định"}');

    Directory? targetDir;

    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        targetDir = Directory('${downloadsDir.path}/bin_esp32');
      } else {
        final extDir = await getExternalStorageDirectory();
        targetDir = Directory('${extDir?.path}/bin_esp32');
      }
    } else if (Platform.isIOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docsDir.path}/bin_esp32');
    }

    // Tạo thư mục nếu chưa tồn tại
    if (targetDir != null && !await targetDir.exists()) {
      debugPrint('[FirmwareService Debug] Tạo thư mục lưu trữ: ${targetDir.path}');
      await targetDir.create(recursive: true);
      debugPrint('[FirmwareService Debug] ✅ Tạo thư mục thành công!');
    }

    // LẤY NGUYÊN TÊN FILE GỐC TỪ CẤU TRÚC URL TRÊN GITHUB RELEASE
    String fileName = url.split('/').last.split('?').first;
    debugPrint('[FirmwareService Debug] Tên file trích xuất từ URL: "$fileName"');

    // Trường hợp dự phòng nếu URL không có đuôi .bin
    if (!fileName.endsWith('.bin')) {
      fileName = version != null ? 'v$version.bin' : 'firmware.bin';
      debugPrint('[FirmwareService Debug] ⚠️ URL không chứa đuôi .bin, chuyển sang tên dự phòng: "$fileName"');
    }

    final savePath = '${targetDir!.path}/$fileName';
    final file = File(savePath);

    debugPrint('[FirmwareService Debug] Đích đến lưu file trên máy: $savePath');

    // Xử lý xóa file cũ trùng tên an toàn
    if (await file.exists()) {
      try {
        debugPrint('[FirmwareService Debug] Phát hiện file cũ trùng tên, tiến hành xóa...');
        await file.delete();
        debugPrint('[FirmwareService Debug] ✅ Đã xóa file cũ thành công.');
      } catch (e) {
        debugPrint('[FirmwareService Debug] ⚠️ Không thể xóa file cũ ($e), sẽ ghi đè trực tiếp.');
      }
    }

    // Cấu hình Dio tối ưu cho Redirect của GitHub Releases
    final dio = Dio(
      BaseOptions(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
          'Accept': '*/*',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 3),
        followRedirects: true,
        maxRedirects: 8,
      ),
    );

    debugPrint('[FirmwareService Debug] 📡 Đang kết nối Server và nhận stream dữ liệu...');

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final percentage = (received / total * 100).toStringAsFixed(0);
          debugPrint('[FirmwareService Debug] Tiến trình tải: $percentage% ($received / $total bytes)');
        } else {
          debugPrint('[FirmwareService Debug] Đang nhận dữ liệu: $received bytes...');
        }
        if (onProgress != null) {
          onProgress(received, total);
        }
      },
      deleteOnError: true,
    );

    // 🟢 2. CẬP NHẬT TẠI ĐÂY: BÁO CHO ANDROID MEDIASTORE INDEX FILE NGAY KHI TẢI XONG
    if (Platform.isAndroid) {
      try {
        await MediaScanner.loadMedia(path: savePath);
        debugPrint('[FirmwareService Debug] 🟢 Đã thông báo Android MediaStore index file thành công!');
      } catch (e) {
        debugPrint('[FirmwareService Debug] ⚠️ Lỗi khi index MediaScanner: $e');
      }
    }

    debugPrint('[FirmwareService Debug] 🎉 Tải thành công Firmware giữ nguyên tên gốc!');
    debugPrint('[FirmwareService Debug] File lưu tại: $savePath');
    debugPrint('--------------------------------------------------');

    localDownloadedBinPath = savePath;
    return savePath;
  }
}