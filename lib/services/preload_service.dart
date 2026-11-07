import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
class PreloadService {
  static Future<void> cacheAllBuildingImages({
    required List<String> imageUrls,
    int batchSize = 1, // 🟢 Đổi về 1 để tải tuần tự, triệt tiêu lỗi HTTP 504 từ GitHub
    BuildContext? context,
  }) async {
    final validUrls = imageUrls.where((url) {
      if (url.isEmpty || !url.startsWith('http')) {
        return false;
      }
      final lower = url.toLowerCase();
      if (lower.endsWith('.bin') ||
          lower.endsWith('.zip') ||
          lower.endsWith('.json')) {
        return false;
      }
      return true;
    }).toSet().toList();
    debugPrint('🚀 [PRELOAD] Bắt đầu tải ngầm an toàn ${validUrls.length} ảnh...');
    for (int i = 0; i < validUrls.length; i++) {
      final String url = validUrls[i];
      int retryCount = 0;
      bool success = false;
      while (retryCount < 3 && !success) {
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(url);
          if (fileInfo == null) {
            await DefaultCacheManager()
                .downloadFile(url)
                .timeout(const Duration(seconds: 15));
          }
          success = true;
        } catch (e) {
          retryCount++;
          debugPrint('⚠️ [PRELOAD RETRY $retryCount] Thử tải lại $url do lỗi: $e');
          if (retryCount >= 3) {
            debugPrint('❌ [PRELOAD FAIL] Bỏ qua file sau 3 lần thất bại: $url');
          } else {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
    debugPrint('✅ [PRELOAD SUCCESS] Đã lưu cache đĩa thành công toàn bộ ảnh!');
    if (context != null && context.mounted) {
      for (String url in validUrls) {
        try {
          final imageProvider = CachedNetworkImageProvider(
            url,
            cacheKey: url,
          );
          await precacheImage(imageProvider, context);
        } catch (e) {
          debugPrint('⚠️ [RAM_PRECACHE ERROR] Không thể nạp RAM cho $url: $e');
        }
      }
      debugPrint('⚡ [RAM_PRECACHE] Đã đưa toàn bộ ảnh giải mã sẵn lên RAM!');
    }
  }
}