import 'dart:io';
import 'package:dio/dio.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
class FirmwareService {
  static String? localDownloadedBinPath;
  static Future<Directory> _getSafeBinDirectory() async {
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
  if (targetDir == null) {
    throw Exception('Không thể khởi tạo đường dẫn bộ nhớ!');
  }
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  return targetDir;
}
  static Future<File?> getLatestDownloadedBinFile() async {
    try {
      final Directory targetDir = await _getSafeBinDirectory();
      final List<FileSystemEntity> entities = await targetDir.list().toList();
      final List<File> binFiles = entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.bin'))
          .toList();
      if (binFiles.isEmpty) return null;
      binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return binFiles.first;
    } catch (e) {
      return null;
    }
  }
  static Future<String> downloadToBinFolder(
    String url, {
    String? version,
    Function(int received, int total)? onProgress,
  }) async {
    final Directory targetDir = await _getSafeBinDirectory();
    String fileName = url.split('/').last.split('?').first;
    if (!fileName.endsWith('.bin')) {
      fileName = version != null ? 'v$version.bin' : 'firmware.bin';
    }
    final savePath = '${targetDir.path}/$fileName';
    final file = File(savePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
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
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (onProgress != null) {
          onProgress(received, total);
        }
      },
      deleteOnError: true,
    );
    if (Platform.isAndroid) {
      try {
        await MediaScanner.loadMedia(path: savePath);
      } catch (_) {}
    }
    localDownloadedBinPath = savePath;
    return savePath;
  }
}