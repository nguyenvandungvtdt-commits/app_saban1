import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:media_scanner/media_scanner.dart'; // 🟢 1. THÊM IMPORT NÀY
import 'package:path_provider/path_provider.dart';
class FirmwareService {
  static String? localDownloadedBinPath;
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
    if (targetDir != null && !await targetDir.exists()) {
      debugPrint('[FirmwareService Debug] Tạo thư mục lưu trữ: ${targetDir.path}');
      await targetDir.create(recursive: true);
      debugPrint('[FirmwareService Debug] ✅ Tạo thư mục thành công!');
    }
    String fileName = url.split('/').last.split('?').first;
    debugPrint('[FirmwareService Debug] Tên file trích xuất từ URL: "$fileName"');
    if (!fileName.endsWith('.bin')) {
      fileName = version != null ? 'v$version.bin' : 'firmware.bin';
      debugPrint('[FirmwareService Debug] ⚠️ URL không chứa đuôi .bin, chuyển sang tên dự phòng: "$fileName"');
    }
    final savePath = '${targetDir!.path}/$fileName';
    final file = File(savePath);
    debugPrint('[FirmwareService Debug] Đích đến lưu file trên máy: $savePath');
    if (await file.exists()) {
      try {
        debugPrint('[FirmwareService Debug] Phát hiện file cũ trùng tên, tiến hành xóa...');
        await file.delete();
        debugPrint('[FirmwareService Debug] ✅ Đã xóa file cũ thành công.');
      } catch (e) {
        debugPrint('[FirmwareService Debug] ⚠️ Không thể xóa file cũ ($e), sẽ ghi đè trực tiếp.');
      }
    }
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