import 'dart:io';
import 'package:flutter/material.dart';
class InteractiveImageViewer extends StatefulWidget {
  final String imagePath;
  final double borderRadius;
  final bool gaplessPlayback; // 🟢 1. Khai báo thuộc tính gaplessPlayback
  const InteractiveImageViewer({
    super.key,
    required this.imagePath,
    this.borderRadius = 16.0,
    this.gaplessPlayback = true, // 🟢 2. Mặc định gán true để giữ đệm ảnh mịn màng
  });
  @override
  State<InteractiveImageViewer> createState() => _InteractiveImageViewerState();
}
class _InteractiveImageViewerState extends State<InteractiveImageViewer> {
  final TransformationController _transformationController = TransformationController();
  Widget _buildSmartImage(
    String path, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
  }) {
    final String trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
    }
    Widget imageWidget;
    if (trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')) {
      imageWidget = Image.network(
        trimmedPath,
        fit: fit,
        width: width,
        height: height,
        alignment: Alignment.center,
        gaplessPlayback: widget.gaplessPlayback, // 🟢 Truyền gaplessPlayback vào Image.network
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported,
          size: 60,
          color: Colors.grey,
        ),
      );
    } else if (trimmedPath.startsWith('assets/')) {
      imageWidget = Image.asset(
        trimmedPath,
        fit: fit,
        width: width,
        height: height,
        alignment: Alignment.center,
        gaplessPlayback: widget.gaplessPlayback, // 🟢 Truyền gaplessPlayback vào Image.asset
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported,
          size: 60,
          color: Colors.grey,
        ),
      );
    } else {
      imageWidget = Image.file(
        File(trimmedPath),
        fit: fit,
        width: width,
        height: height,
        alignment: Alignment.center,
        gaplessPlayback: widget.gaplessPlayback, // 🟢 Truyền gaplessPlayback vào Image.file
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: imageWidget,
    );
  }
  ImageProvider _getSmartImageProvider(String path) {
    final String trimmedPath = path.trim();
    if (trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')) {
      return NetworkImage(trimmedPath);
    } else if (trimmedPath.startsWith('assets/')) {
      return AssetImage(trimmedPath);
    } else {
      return FileImage(File(trimmedPath));
    }
  }
  void _zoom(double factor) {
    final Matrix4 currentMatrix = _transformationController.value;
    final Matrix4 newMatrix = currentMatrix.scaledByDouble(factor, factor, 1.0, 1.0);
    _transformationController.value = newMatrix;
  }
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
  void _openFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TransformationController fullScreenController = TransformationController();
        bool isImageLoaded = false;
        bool shouldFitCover = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!isImageLoaded) {
              final ImageStream stream = _getSmartImageProvider(widget.imagePath)
                  .resolve(const ImageConfiguration());
              stream.addListener(
                ImageStreamListener((ImageInfo info, bool _) {
                  if (context.mounted) {
                    final double imageAspectRatio = info.image.width / info.image.height;
                    final double screenAspectRatio =
                        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
                    final double diff = (imageAspectRatio - screenAspectRatio).abs();
                    setModalState(() {
                      shouldFitCover = diff < 0.25;
                      isImageLoaded = true;
                    });
                  }
                }),
              );
            }
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF0F172A), // Màu nền tối phông chuẩn
                    ),
                  ),
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: fullScreenController,
                      boundaryMargin: const EdgeInsets.all(100),
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Center(
                        child: _buildSmartImage(
                          widget.imagePath,
                          fit: shouldFitCover ? BoxFit.cover : BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: SafeArea(
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          '• Vuốt/Kéo để di chuyển  |  • Cuộn chuột hoặc dùng 2 ngón tay để Zoom',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        alignment: Alignment.center, // Căn giữa toàn bộ lớp Stack
        children: [
          GestureDetector(
            onTap: () => _openFullScreen(context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox.expand( // Ép mở rộng phủ kín vùng chứa
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  alignment: Alignment.center, // Căn giữa ma trận zoom
                  child: Center( // Căn giữa ảnh tuyệt đối
                    child: _buildSmartImage(
                      widget.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolButton(
                    icon: Icons.add,
                    tooltip: 'Phóng to',
                    onTap: () => _zoom(1.25),
                  ),
                  _buildToolButton(
                    icon: Icons.remove,
                    tooltip: 'Thu nhỏ',
                    onTap: () => _zoom(0.8),
                  ),
                  _buildToolButton(
                    icon: Icons.restart_alt,
                    tooltip: 'Về ban đầu',
                    onTap: _resetZoom,
                  ),
                  const SizedBox(width: 4),
                  Container(height: 16, width: 1, color: Colors.white30),
                  const SizedBox(width: 4),
                  _buildToolButton(
                    icon: Icons.fullscreen,
                    tooltip: 'Mở toàn màn hình',
                    onTap: () => _openFullScreen(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}