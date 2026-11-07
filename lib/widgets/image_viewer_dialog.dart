import 'package:flutter/material.dart';
import 'interactive_image_viewer.dart';
class ImageViewerDialog {
  static void show(BuildContext context, String imagePath, {String? title}) {
    if (imagePath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy đường dẫn hình ảnh!')),
      );
      return;
    }
    showDialog(
      context: context,
      useRootNavigator: true, // 🟢 BẮT BUỘC: Đẩy Dialog đè lên trên BottomSheet
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveImageViewer(
                  imagePath: imagePath,
                  borderRadius: 0, // Không bo tròn khi xem toàn màn hình
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title ?? 'Chi Tiết Hình Ảnh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 1)),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}