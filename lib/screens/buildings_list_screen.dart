import 'dart:ui';
import 'package:flutter/material.dart';
import 'floors_list_screen.dart';
// import '../services/config_service.dart';
import '../widgets/dynamic_image.dart';
// import 'dart:convert';
class BuildingsListScreen extends StatefulWidget {
  final Map<String, dynamic>? configData;
  final List<Map<String, dynamic>> buildings;
  final Map<int, bool> ledStates;
  final Function(List<int> leds, bool state) onToggleLeds;
  final bool Function(List<int> leds) isAnyLedOn;
  final List<int> Function(List<dynamic> rooms, {int? filterRoomType}) extractLeds;
  final int selectedFilterType;
  // final Map<String, dynamic>? configData;
  const BuildingsListScreen({
    super.key,
    required this.buildings,
    required this.ledStates,
    required this.onToggleLeds,
    required this.isAnyLedOn,
    required this.extractLeds,
    required this.selectedFilterType,
    this.configData, // 🟢 2. Thêm tham số vào constructor
  });
  @override
  State<BuildingsListScreen> createState() => _BuildingsListScreenState();
}
class _BuildingsListScreenState extends State<BuildingsListScreen> {
  List<int> _getBuildingLeds(Map<String, dynamic> building) {
    List<int> leds = [];
    for (var f in building['floors']) {
      leds.addAll(widget.extractLeds(f['rooms'], filterRoomType: widget.selectedFilterType));
    }
    return leds;
  }
  // @override
  // Widget build(BuildContext context) {
  //   const String buildingImagePath = 'assets/images/building.jpg';
  //   return Scaffold(
  //     body: Stack(
  //       fit: StackFit.expand,
  //       children: [
  //         // 1. Nền mờ Glassmorphism
  //         Positioned.fill(
  //           child: Image.asset(
  //             buildingImagePath,
  //             fit: BoxFit.cover,
  //             errorBuilder: (context, error, stackTrace) =>
  //                 Container(color: const Color(0xFFE0F2FE)),
  //           ),
  //         ),
  //         Positioned.fill(
  //           child: BackdropFilter(
  //             filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
  //             child: Container(
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                   colors: [
  //                     const Color(0xFFF0F9FF).withValues(alpha: 0.88),
  //                     const Color(0xFFE0F2FE).withValues(alpha: 0.82),
  //                     const Color(0xFFF8FAFC).withValues(alpha: 0.92),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //         // 2. Nội dung Giao diện
  //         SafeArea(
  //           child: LayoutBuilder(
  //             builder: (context, constraints) {
  //               double screenWidth = constraints.maxWidth;
  //               bool isPhone = screenWidth < 600;
  //               return Column(
  //                 children: [
  //                   _buildTopBar(context),
  //                   // KHU VỰC HIỂN THỊ SA BÀN TÒA NHÀ (ADAPTIVE FIT)
  //                   Expanded(
  //                     child: Padding(
  //                       padding: EdgeInsets.symmetric(
  //                         horizontal: isPhone ? 10.0 : 16.0,
  //                         vertical: isPhone ? 4.0 : 6.0,
  //                       ),
  //                       child: ClipRRect(
  //                         borderRadius: BorderRadius.circular(20),
  //                         child: InteractiveViewer(
  //                           minScale: 1.0,
  //                           maxScale: 4.0,
  //                           child: Center(
  //                             child: Image.asset(
  //                               buildingImagePath,
  //                               width: double.infinity,
  //                               height: double.infinity,
  //                               fit: isPhone ? BoxFit.contain : BoxFit.fitWidth,
  //                               alignment: Alignment.center,
  //                               errorBuilder: (context, error, stackTrace) =>
  //                                   Container(color: Colors.white),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   // BẢNG ĐIỀU KHIỂN TÒA NHÀ CĂN GIỮA ADAPTIVE
  //                   Padding(
  //                     padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
  //                     child: _buildAdaptiveBuildingPanel(context, isPhone),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
//   @override
// Widget build(BuildContext context) {
//   // 🟢 1. Lấy link ảnh từ Cloud config, nếu chưa có mới dùng fallback asset
//   String buildingImagePath = widget.configData?['assets']?['building_default'] ??
//       'assets/images/building.jpg';

//   if (buildingImagePath.trim().isEmpty) {
//     buildingImagePath = 'assets/images/building.jpg';
//   }

//   return Scaffold(
//     body: Stack(
//       fit: StackFit.expand,
//       children: [
//         // 1. Nền mờ Glassmorphism (Dùng DynamicImage để mờ chuẩn theo ảnh Cloud)
//         Positioned.fill(
//           child: DynamicImage(
//             imagePath: buildingImagePath,
//             fit: BoxFit.cover,
//             fallbackAsset: 'assets/images/building.jpg',
//           ),
//         ),
//         Positioned.fill(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     const Color(0xFFF0F9FF).withValues(alpha: 0.88),
//                     const Color(0xFFE0F2FE).withValues(alpha: 0.82),
//                     const Color(0xFFF8FAFC).withValues(alpha: 0.92),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//         // 2. Nội dung Giao diện
//         SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               double screenWidth = constraints.maxWidth;
//               bool isPhone = screenWidth < 600;
//               return Column(
//                 children: [
//                   _buildTopBar(context),
//                   // KHU VỰC HIỂN THỊ SA BÀN TÒA NHÀ (ADAPTIVE FIT)
//                   Expanded(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isPhone ? 10.0 : 16.0,
//                         vertical: isPhone ? 4.0 : 6.0,
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: InteractiveViewer(
//                           minScale: 1.0,
//                           maxScale: 4.0,
//                           child: Center(
//                             // 🟢 2. Render ảnh chính bằng DynamicImage hỗ trợ cả URL Cloud & Asset local
//                             child: SizedBox(
//                               width: double.infinity,
//                               height: double.infinity,
//                               child: DynamicImage(
//                                 imagePath: buildingImagePath,
//                                 fit: isPhone ? BoxFit.contain : BoxFit.fitWidth,
//                                 alignment: Alignment.center,
//                                 fallbackAsset: 'assets/images/building.jpg',
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   // BẢNG ĐIỀU KHIỂN TÒA NHÀ CĂN GIỮA ADAPTIVE
//                   Padding(
//                     padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
//                     child: _buildAdaptiveBuildingPanel(context, isPhone),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ],
//     ),
//   );
// }
@override
Widget build(BuildContext context) {
  // 🟢 1. Lấy dữ liệu config từ widget truyền sang
  final Map<String, dynamic>? configMap = widget.configData;

  // 🟢 2. Trích xuất link ảnh Cloud (building_default -> overview -> asset local)
  final Map<String, dynamic>? assetsMap = configMap?['assets'] as Map<String, dynamic>?;
  final String? rawBuildingImg = (assetsMap?['building_default'] ?? assetsMap?['overview']) as String?;

  final String buildingImagePath = (rawBuildingImg != null && rawBuildingImg.trim().isNotEmpty)
      ? rawBuildingImg
      : 'assets/images/building.jpg';

  // 🔍 3. DEBUG PRINT KIỂM TRA
  debugPrint('--------------------------------------------------');
  debugPrint('🏢 [DEBUG BUILDING SCREEN] Config Map có dữ liệu? ${configMap != null}');
  debugPrint('🏢 [DEBUG BUILDING SCREEN] RAW Key building_default: "$rawBuildingImg"');
  debugPrint('🏢 [DEBUG BUILDING SCREEN] Path ảnh hiển thị: "$buildingImagePath"');
  if (buildingImagePath.startsWith('http')) {
    debugPrint('✨ [SUCCESS] Đã nhận URL Cloud từ GitHub: $buildingImagePath');
  } else {
    debugPrint('⚠️ [FALLBACK] Đang dùng asset local: $buildingImagePath');
  }
  debugPrint('--------------------------------------------------');

  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        // 1. Nền mờ Glassmorphism
        Positioned.fill(
          child: DynamicImage(
            imagePath: buildingImagePath,
            fit: BoxFit.cover,
            fallbackAsset: 'assets/images/building.jpg',
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF0F9FF).withValues(alpha: 0.88),
                    const Color(0xFFE0F2FE).withValues(alpha: 0.82),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 2. Nội dung Giao diện
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              bool isPhone = screenWidth < 600;
              return Column(
                children: [
                  _buildTopBar(context),
                  // KHU VỰC HIỂN THỊ SA BÀN TÒA NHÀ
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 10.0 : 16.0,
                        vertical: isPhone ? 4.0 : 6.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: DynamicImage(
                                imagePath: buildingImagePath,
                                fit: isPhone ? BoxFit.contain : BoxFit.fitWidth,
                                alignment: Alignment.center,
                                fallbackAsset: 'assets/images/building.jpg',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // BẢNG ĐIỀU KHIỂN TÒA NHÀ GỐC
                  Padding(
                    padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                    child: _buildAdaptiveBuildingPanel(context, isPhone),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF0369A1), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFBAE6FD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.domain_rounded,
                      size: 18,
                      color: Color(0xFF0369A1),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DANH SÁCH TÒA NHÀ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
  Widget _buildAdaptiveBuildingPanel(BuildContext context, bool isPhone) {
    double spacing = isPhone ? 4.0 : 12.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 8 : 16, vertical: isPhone ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune,
                  size: isPhone ? 13 : 15, color: const Color(0xFF0369A1)),
              const SizedBox(width: 4),
              Text(
                'ĐIỀU KHIỂN TÒA NHÀ SA BÀN',
                style: TextStyle(
                  fontSize: isPhone ? 11 : 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0369A1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 6 : 10),
          // HÀNG NÚT DÀN NGANG CĂN GIỮA ĐÃ SỬA LỖI RENDERFLEX
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: widget.buildings.asMap().entries.map((entry) {
              int index = entry.key;
              var b = entry.value;
              Widget item = _buildBuildingButton(b, isPhone);
              return isPhone
                  ? Flexible(
                      fit: FlexFit.tight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.buildings.length - 1 ? 0 : spacing,
                        ),
                        child: item,
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.buildings.length - 1 ? 0 : spacing,
                      ),
                      child: SizedBox(width: 140.0, child: item),
                    );
            }).toList(),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '• Chạm 1 lần: Bật/Tắt Tòa   |   • Nhấn đúp 2 lần: Danh sách tầng',
              style: TextStyle(
                fontSize: isPhone ? 9.0 : 10.5,
                color: const Color(0xFF0284C7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBuildingButton(Map<String, dynamic> b, bool isPhone) {
    List<int> bLeds = _getBuildingLeds(b);
    bool isOn = widget.isAnyLedOn(bLeds);
    return InkWell(
      onTap: () {
        widget.onToggleLeds(bLeds, !isOn);
        setState(() {});
      },
      onDoubleTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FloorsListScreen(
              buildingName: b['name'],
              floors: b['floors'],
              ledStates: widget.ledStates,
              onToggleLeds: widget.onToggleLeds,
              isAnyLedOn: widget.isAnyLedOn,
              extractLeds: widget.extractLeds,
              selectedFilterType: widget.selectedFilterType,
              configData: widget.configData, // 🟢 Truyền tiếp configData sang Floors
            ),
          ),
        );
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 2 : 8,
          vertical: isPhone ? 6 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isOn
              ? const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? Colors.amberAccent : const Color(0xFFF472B6),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isPhone ? 2 : 4),
              decoration: BoxDecoration(
                color: isOn
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF472B6).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOn ? Icons.lightbulb : Icons.apartment,
                size: isPhone ? 11 : 13,
                color: isOn ? Colors.white : const Color(0xFFDB2777),
              ),
            ),
            SizedBox(width: isPhone ? 2 : 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      b['name'] ?? 'TÒA NHÀ',
                      style: TextStyle(
                        fontSize: isPhone ? 10.0 : 12.0,
                        fontWeight: FontWeight.bold,
                        color: isOn ? Colors.white : const Color(0xFF831843),
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${bLeds.length} p | ${isOn ? "BẬT" : "TẮT"}',
                      style: TextStyle(
                        fontSize: isPhone ? 7.5 : 8.5,
                        fontWeight: isOn ? FontWeight.bold : FontWeight.w600,
                        color:
                            isOn ? Colors.yellow.shade100 : const Color(0xFF9D174D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}