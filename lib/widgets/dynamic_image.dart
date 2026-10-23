import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
class DynamicImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final String fallbackAsset;
  final Alignment alignment;
  const DynamicImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.fallbackAsset = 'assets/images/overview.jpg',
    this.alignment = Alignment.center,
  });
  @override
  Widget build(BuildContext context) {
    if (imagePath.trim().isEmpty) {
      return _buildFallbackAsset();
    }
    // if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    //   return CachedNetworkImage(
    //     imageUrl: imagePath,
    //     fit: fit,
    //     alignment: alignment,
    //     placeholder: (context, url) => Stack(
    //       fit: StackFit.expand,
    //       children: [
    //         _buildFallbackAsset(),
    //         const Center(
    //           child: CircularProgressIndicator(
    //             color: Colors.cyanAccent,
    //             strokeWidth: 2,
    //           ),
    //         ),
    //       ],
    //     ),
    //     errorWidget: (context, url, error) => _buildFallbackAsset(),
    //   );
    // }
    // Trong file dynamic_image.dart
if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
  return CachedNetworkImage(
    imageUrl: imagePath,
    fit: fit,
    alignment: alignment,
    
    // 🟢 SỬA ĐOẠN NÀY: Bỏ CircularProgressIndicator, thay bằng khung màu nền hoặc ảnh fallback
    placeholder: (context, url) => _buildFallbackAsset(), 
    
    // Tạo hiệu ứng hiện ảnh mượt mà 200ms khi nạp xong
    fadeInDuration: const Duration(milliseconds: 200),
    
    errorWidget: (context, url, error) => _buildFallbackAsset(),
  );
}
    if (kIsWeb || imagePath.startsWith('blob:')) {
      return Image.network(
        imagePath,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
      );
    }
    if (!kIsWeb && !imagePath.startsWith('assets/')) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
          );
        }
      } catch (e) {
        debugPrint('⚠️ DynamicImage File Check Error: $e');
      }
    }
    return Image.asset(
      imagePath,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
    );
  }
  Widget _buildFallbackAsset() {
    return Image.asset(
      fallbackAsset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, err, stack) => Container(
        color: Colors.grey.shade900,
        child: const Icon(Icons.broken_image, color: Colors.white38, size: 48),
      ),
    );
  }
}