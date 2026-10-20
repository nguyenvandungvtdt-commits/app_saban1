// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:dio/dio.dart';
// import 'package:media_scanner/media_scanner.dart';

// class FirmwareService {
//   static String? localDownloadedBinPath;

//   /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
//   /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
//   static Future<String?> downloadToBinFolder(String downloadUrl, {String? version}) async {
//     try {
//       // 🟢 Khởi tạo giá trị mặc định để tránh lỗi "must be assigned before it can be used"
//       Directory customFolder = await getTemporaryDirectory();

//       if (Platform.isAndroid) {
//         // --- CẤU HÌNH DÀNH CHO ANDROID ---
//         final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
//         bool canWritePublic = false;
//         try {
//           if (!await publicDownloadDir.exists()) {
//             await publicDownloadDir.create(recursive: true);
//           }
//           final testFile = File('${publicDownloadDir.path}/.test_write');
//           await testFile.writeAsString('test');
//           await testFile.delete();
//           canWritePublic = true;
//           customFolder = publicDownloadDir;
//         } catch (_) {
//           canWritePublic = false;
//         }

//         if (!canWritePublic) {
//           final externalDir = await getExternalStorageDirectory();
//           final fallbackDir = Directory('${externalDir?.path}/bin_esp32');
//           if (!await fallbackDir.exists()) {
//             await fallbackDir.create(recursive: true);
//           }
//           customFolder = fallbackDir;
//         }
//       } else if (Platform.isIOS) {
//         // --- CẤU HÌNH DÀNH CHO IOS (APP STORE) ---
//         final docsDir = await getApplicationDocumentsDirectory();
//         final iosFolder = Directory('${docsDir.path}/bin_esp32');
//         if (!await iosFolder.exists()) {
//           await iosFolder.create(recursive: true);
//         }
//         customFolder = iosFolder;
//       }

//       // Xóa các file .bin cũ trong thư mục
//       if (await customFolder.exists()) {
//         final files = customFolder.listSync();
//         for (var file in files) {
//           if (file.path.endsWith('.bin')) {
//             await file.delete();
//           }
//         }
//       }

//       final fileName = version != null ? 'firmware_v$version.bin' : 'firmware_latest.bin';
//       final filePath = '${customFolder.path}/$fileName';

//       debugPrint('[OTA] Đường dẫn lưu file (${Platform.operatingSystem}): $filePath');

//       final dio = Dio();
//       await dio.download(
//         downloadUrl, 
//         filePath,
//         options: Options(
//           responseType: ResponseType.bytes,
//           followRedirects: true,
//           maxRedirects: 10,
//           headers: {
//             'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
//           },
//         ),
//       );

//       final downloadedFile = File(filePath);
//       if (await downloadedFile.exists()) {
//         final fileSize = await downloadedFile.length();
//         debugPrint('[OTA] Tải thành công! Kích thước: $fileSize bytes');

//         if (fileSize > 50000) {
//           localDownloadedBinPath = filePath;

//           // Chỉ quét MediaScanner trên Android
//           if (Platform.isAndroid) {
//             try {
//               await MediaScanner.loadMedia(path: filePath);
//             } catch (e) {
//               debugPrint('[OTA] Lỗi MediaScanner Android: $e');
//             }
//           }

//           return filePath;
//         } else {
//           await downloadedFile.delete();
//           throw Exception("File tải về quá nhỏ ($fileSize bytes).");
//         }
//       } else {
//         throw Exception("Không thể tạo file tại đường dẫn chỉ định.");
//       }

//     } catch (e) {
//       debugPrint('[OTA] Lỗi tải file Firmware: $e');
//       return null;
//     }
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:media_scanner/media_scanner.dart';

class FirmwareService {
  static String? localDownloadedBinPath;
  // 🟢 Thêm phương thức lấy thư mục lưu trữ tùy theo OS
  static Future<Directory> getSavedBinFolder() async {
    if (Platform.isAndroid) {
      final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
      if (await publicDownloadDir.exists()) {
        return publicDownloadDir;
      }
      final externalDir = await getExternalStorageDirectory();
      return Directory('${externalDir?.path}/bin_esp32');
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      return Directory('${docsDir.path}/bin_esp32');
    }
  }

  // 🟢 Thêm phương thức tìm file .bin mới nhất trong thư mục
  static Future<File?> getLatestDownloadedBinFile() async {
    final folder = await getSavedBinFolder();
    if (await folder.exists()) {
      final files = folder.listSync().whereType<File>().where((f) => f.path.endsWith('.bin')).toList();
      if (files.isNotEmpty) {
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        return files.first;
      }
    }
    return null;
  }

  /// Tải file .bin về thư mục phù hợp với từng hệ điều hành (Android / iOS)
  static Future<String?> downloadToBinFolder(
    String downloadUrl, {
    String? version,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 🟢 Khởi tạo giá trị mặc định để tránh lỗi "must be assigned before it can be used"
      Directory customFolder = await getTemporaryDirectory();

      if (Platform.isAndroid) {
        // --- CẤU HÌNH DÀNH CHO ANDROID ---
        final publicDownloadDir = Directory('/storage/emulated/0/Download/bin_esp32');
        bool canWritePublic = false;
        try {
          if (!await publicDownloadDir.exists()) {
            await publicDownloadDir.create(recursive: true);
          }
          final testFile = File('${publicDownloadDir.path}/.test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          canWritePublic = true;
          customFolder = publicDownloadDir;
        } catch (_) {
          canWritePublic = false;
        }

        if (!canWritePublic) {
          final externalDir = await getExternalStorageDirectory();
          final fallbackDir = Directory('${externalDir?.path}/bin_esp32');
          if (!await fallbackDir.exists()) {
            await fallbackDir.create(recursive: true);
          }
          customFolder = fallbackDir;
        }
      } else if (Platform.isIOS) {
        // --- CẤU HÌNH DÀNH CHO IOS / IPAD OS (APP STORE) ---
        final docsDir = await getApplicationDocumentsDirectory();
        final iosFolder = Directory('${docsDir.path}/bin_esp32');
        if (!await iosFolder.exists()) {
          await iosFolder.create(recursive: true);
        }
        customFolder = iosFolder;
      }

      // Xóa các file .bin cũ trong thư mục
      if (await customFolder.exists()) {
        final files = customFolder.listSync();
        for (var file in files) {
          if (file.path.endsWith('.bin')) {
            await file.delete();
          }
        }
      }

      final fileName = version != null ? 'firmware_v$version.bin' : 'firmware_latest.bin';
      final filePath = '${customFolder.path}/$fileName';

      debugPrint('[OTA] Đường dẫn lưu file (${Platform.operatingSystem}): $filePath');

      final dio = Dio();
      await dio.download(
        downloadUrl, 
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 10,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
          },
        ),
      );

      final downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        final fileSize = await downloadedFile.length();
        debugPrint('[OTA] Tải thành công! Kích thước: $fileSize bytes');

        if (fileSize > 50000) {
          localDownloadedBinPath = filePath;

          // Chỉ quét MediaScanner trên Android
          if (Platform.isAndroid) {
            try {
              await MediaScanner.loadMedia(path: filePath);
            } catch (e) {
              debugPrint('[OTA] Lỗi MediaScanner Android: $e');
            }
          }

          return filePath;
        } else {
          await downloadedFile.delete();
          throw Exception("File tải về quá nhỏ ($fileSize bytes).");
        }
      } else {
        throw Exception("Không thể tạo file tại đường dẫn chỉ định.");
      }

    } catch (e) {
      debugPrint('[OTA] Lỗi tải file Firmware: $e');
      return null;
    }
  }
}