import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
class DynamicImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final String fallbackAsset;
  final Alignment alignment;
  final double borderRadius;
  final bool gaplessPlayback; // 🟢 Bổ sung cờ chống nháy đệm RAM
  const DynamicImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.fallbackAsset = 'assets/images/overview.jpg',
    this.alignment = Alignment.center,
    this.borderRadius = 20.0,
    this.gaplessPlayback = true, // 🟢 Mặc định true để giữ mịn đệm ảnh cũ
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImageContent(),
    );
  }
  Widget _buildImageContent() {
    final String trimmedPath = imagePath.trim();
    if (trimmedPath.isEmpty) {
      return _buildFallbackAsset('Trống đường dẫn');
    }
    Widget content;
    if (kIsWeb || trimmedPath.startsWith('blob:')) {
      content = Image.network(
        trimmedPath,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAsset('Lỗi nạp Web/Blob Image: $error'),
      );
    }
    else if (!kIsWeb && !trimmedPath.startsWith('assets/')) {
      try {
        final file = File(trimmedPath);
        if (file.existsSync()) {
          content = Image.file(
            file,
            fit: fit,
            alignment: alignment,
            gaplessPlayback: gaplessPlayback,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackAsset('Lỗi nạp File Local: $error'),
          );
        } else {
          content = _buildFallbackAsset('File không tồn tại: $trimmedPath');
        }
      } catch (e) {
        content = _buildFallbackAsset('Lỗi kiểm tra File: $e');
      }
    }
    else {
      content = Image.asset(
        trimmedPath,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAsset('Không tìm thấy Asset Local: $error'),
      );
    }
    if (fit == BoxFit.contain) {
      return Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: alignment,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }
  Widget _buildFallbackAsset(String reason) {
    return Image.asset(
      fallbackAsset,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (context, err, stack) => Container(
        color: Colors.grey.shade900,
        child: const Icon(Icons.broken_image, color: Colors.white38, size: 48),
      ),
    );
  }
}