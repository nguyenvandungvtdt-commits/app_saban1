import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rooms_list_screen.dart';
import '../widgets/info_dialog.dart';
import '../services/websocket_service.dart';
import '../services/config_service.dart';
import '../widgets/dynamic_image.dart';
import 'dart:convert';
class FloorsListScreen extends StatefulWidget {
  final Map<String, dynamic>? configData;
  final String buildingName;
  final List<dynamic> floors;
  final Map<int, bool> ledStates;
  final Function(List<int> leds, bool state) onToggleLeds;
  final bool Function(List<int> leds) isAnyLedOn;
  final List<int> Function(List<dynamic> rooms, {int? filterRoomType}) extractLeds;
  final int selectedFilterType;
  final String? buildingImageConfig;
  const FloorsListScreen({
    super.key,
    required this.buildingName,
    required this.floors,
    required this.ledStates,
    required this.onToggleLeds,
    required this.isAnyLedOn,
    required this.extractLeds,
    required this.selectedFilterType,
    this.buildingImageConfig,
    this.configData, // 🟢 2. Thêm tham số named parameter configData vào đây
  });
  @override
  State<FloorsListScreen> createState() => _FloorsListScreenState();
}
class _FloorsListScreenState extends State<FloorsListScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  List<List<dynamic>> _chunkFloors(List<dynamic> floorsList, int itemsPerRow) {
    List<List<dynamic>> chunks = [];
    for (int i = 0; i < floorsList.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < floorsList.length) ? i + itemsPerRow : floorsList.length;
      chunks.add(floorsList.sublist(i, end));
    }
    return chunks;
  }
//   @override
//   Widget build(BuildContext context) {
//     final String floorImagePath = widget.buildingImageConfig ?? 'assets/images/floor.jpg';
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Positioned.fill(
//             child: floorImagePath.startsWith('http')
//                 ? Image.network(floorImagePath, fit: BoxFit.cover)
//                 : Image.asset(floorImagePath, fit: BoxFit.cover),
//           ),
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       const Color(0xFFF0F9FF).withValues(alpha: 0.88), // Sky 50
//                       const Color(0xFFE0F2FE).withValues(alpha: 0.82), // Sky 100
//                       const Color(0xFFF8FAFC).withValues(alpha: 0.92), // Slate 50
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 double screenWidth = constraints.maxWidth;
//                 bool isPhone = screenWidth < 600;
//                 return Column(
//                   children: [
//                     _buildTopBar(context),
// Expanded(
//   child: Padding(
//     padding: EdgeInsets.symmetric(
//       horizontal: isPhone ? 12.0 : 16.0,
//       vertical: isPhone ? 4.0 : 8.0,
//     ),
//     child: Center(
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF0284C7).withValues(alpha: 0.22),
//               blurRadius: 24,
//               spreadRadius: 1,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: InteractiveViewer(
//             minScale: 1.0,
//             maxScale: 4.0,
//             child: floorImagePath.startsWith('http')
//                 ? Image.network(
//                     floorImagePath,
//                     fit: BoxFit.contain, // Hiển thị 100% nguyên bản ảnh tầng, không che khuất
//                     alignment: Alignment.center,
//                     loadingBuilder: (context, child, progress) {
//                       if (progress == null) return child;
//                       return const Center(
//                         child: CircularProgressIndicator(color: Color(0xFF0284C7)),
//                       );
//                     },
//                     errorBuilder: (context, error, stackTrace) =>
//                         Container(color: Colors.white),
//                   )
//                 : Image.asset(
//                     floorImagePath,
//                     fit: BoxFit.contain, // Hiển thị 100% nguyên bản ảnh tầng, không che khuất
//                     alignment: Alignment.center,
//                     errorBuilder: (context, error, stackTrace) =>
//                         Container(color: Colors.white),
//                   ),
//           ),
//         ),
//       ),
//     ),
//   ),
// ),
//                     Padding(
//                       padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
//                       child: _buildAdaptiveControlPanel(context, screenWidth, isPhone),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
@override
Widget build(BuildContext context) {
  // 🟢 1. Lấy dữ liệu config từ widget hoặc đọc từ Cache local
  Map<String, dynamic>? configMap = widget.configData;

  if (configMap == null) {
    try {
      dynamic rawConfig = ConfigService.getSavedJsonConfig();
      if (rawConfig is String && rawConfig.isNotEmpty) {
        configMap = jsonDecode(rawConfig) as Map<String, dynamic>?;
      } else if (rawConfig is Map<String, dynamic>) {
        configMap = rawConfig;
      }
    } catch (e) {
      debugPrint('⚠️ [FLOORS SCREEN] Lỗi giải mã config JSON: $e');
    }
  }

  // 🟢 2. Trích xuất đường dẫn ảnh (Ưu tiên: floor_default -> overview -> buildingImageConfig -> asset local)
  final Map<String, dynamic>? assetsMap = configMap?['assets'] as Map<String, dynamic>?;
  final String? rawFloorImg = (assetsMap?['floor_default'] ?? assetsMap?['overview']) as String?;

  String floorImagePath = (rawFloorImg != null && rawFloorImg.trim().isNotEmpty)
      ? rawFloorImg
      : (widget.buildingImageConfig ?? 'assets/images/floor.jpg');

  if (floorImagePath.trim().isEmpty) {
    floorImagePath = 'assets/images/floor.jpg';
  }

  // 🔍 3. DEBUG PRINT KIỂM TRA DỮ LIỆU TẢI
  debugPrint('--------------------------------------------------');
  debugPrint('🏢 [DEBUG FLOORS SCREEN] Config Map tồn tại? ${configMap != null}');
  debugPrint('🏢 [DEBUG FLOORS SCREEN] RAW Key floor_default/overview: "$rawFloorImg"');
  debugPrint('🏢 [DEBUG FLOORS SCREEN] Path ảnh hiển thị cuối: "$floorImagePath"');
  if (floorImagePath.startsWith('http')) {
    debugPrint('✨ [SUCCESS FLOORS] Đã nhận URL Cloud từ GitHub: $floorImagePath');
  } else {
    debugPrint('⚠️ [FALLBACK FLOORS] Đang dùng asset local: $floorImagePath');
  }
  debugPrint('--------------------------------------------------');

  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        // 1. Nền mờ Glassmorphism (Dùng DynamicImage đồng bộ)
        Positioned.fill(
          child: DynamicImage(
            imagePath: floorImagePath,
           fit: BoxFit.cover, // 🟢 Tràn viền khớp với khung bo tròn
            fallbackAsset: 'assets/images/floor.jpg',
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
                    const Color(0xFFF0F9FF).withValues(alpha: 0.88), // Sky 50
                    const Color(0xFFE0F2FE).withValues(alpha: 0.82), // Sky 100
                    const Color(0xFFF8FAFC).withValues(alpha: 0.92), // Slate 50
                  ],
                ),
              ),
            ),
          ),
        ),
        // 2. Giao diện chính
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              bool isPhone = screenWidth < 600;
              return Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 12.0 : 16.0,
                        vertical: isPhone ? 4.0 : 8.0,
                      ),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: DynamicImage(
                                  imagePath: floorImagePath,
                                  fit: BoxFit.contain, // Hiển thị 100% nguyên bản ảnh tầng
                                  alignment: Alignment.center,
                                  fallbackAsset: 'assets/images/floor.jpg',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                    child: _buildAdaptiveControlPanel(context, screenWidth, isPhone),
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
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0369A1), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0F2FE), // Light Sky
                      Color(0xFFBAE6FD), // Sky Blue
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      size: 18,
                      color: Color(0xFF0369A1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.buildingName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1), // Màu xanh biển đậm nổi bật
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0284C7),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                onPressed: () {
                  InfoDialog.show(
                    context,
                    title: 'Thông Tin ${widget.buildingName}',
                    details: {
                      'Quy mô': '${widget.floors.length} Tầng nổi',
                      'Tổng số căn': 'Căn hộ cao cấp',
                      'Trạng thái': 'Đang mở bán',
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildAdaptiveControlPanel(BuildContext context, double screenWidth, bool isPhone) {
  int targetRows = 3;
  int itemsPerRow = (widget.floors.length / targetRows).ceil();
  if (itemsPerRow < 1) itemsPerRow = 1;
  List<List<dynamic>> floorRows = _chunkFloors(widget.floors, itemsPerRow);
  double horizontalSpacing = isPhone ? 4.0 : 6.0;
  double verticalSpacing = isPhone ? 4.0 : 6.0;
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: isPhone ? 6 : 12, vertical: isPhone ? 6 : 8),
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
            Icon(Icons.tune, size: isPhone ? 13 : 15, color: const Color(0xFF0369A1)),
            const SizedBox(width: 4),
            Text(
              'ĐIỀU KHIỂN TẦNG SA BÀN',
              style: TextStyle(
                fontSize: isPhone ? 11 : 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0369A1),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: isPhone ? 5 : 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: floorRows.map((rowItems) {
              return Padding(
                padding: EdgeInsets.only(bottom: verticalSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: rowItems.map((f) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalSpacing / 2),
                      child: _buildCompactButton(f, isPhone), // 🟢 Nút gốc nét đẹp
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '• Chạm 1 lần: Bật/Tắt Tầng   |   • Nhấn đúp 2 lần: Danh sách căn hộ',
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
Widget _buildCompactButton(dynamic f, bool isPhone) {
  List<int> fLeds = widget.extractLeds(f['rooms'], filterRoomType: widget.selectedFilterType);
  bool isOn = widget.isAnyLedOn(fLeds);
  double buttonWidth = isPhone ? 90.0 : 135.0; 
  return InkWell(
    onTap: () {
      bool newState = !isOn;
      widget.onToggleLeds(fLeds, newState);
      WebSocketService().sendGroupRooms(fLeds, newState);
      setState(() {});
    },
    onDoubleTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomsListScreen(
            floorName: '${widget.buildingName} - ${f['name']}',
            rooms: f['rooms'],
            ledStates: widget.ledStates,
            onToggleLeds: widget.onToggleLeds,
            isAnyLedOn: widget.isAnyLedOn,
            configData: widget.configData,
          ),
        ),
      );
      setState(() {});
    },
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: buttonWidth, // 🟢 Chuẩn kích thước ban đầu
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 4 : 8,
        vertical: isPhone ? 5 : 7,
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
        borderRadius: BorderRadius.circular(8),
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
            padding: EdgeInsets.all(isPhone ? 2.0 : 3.5),
            decoration: BoxDecoration(
              color: isOn
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFFF472B6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOn ? Icons.lightbulb : Icons.layers,
              size: isPhone ? 10.0 : 13.0,
              color: isOn ? Colors.white : const Color(0xFFDB2777),
            ),
          ),
          SizedBox(width: isPhone ? 4 : 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    f['name'] ?? 'TẦNG',
                    style: TextStyle(
                      fontSize: isPhone ? 9.5 : 11.0,
                      fontWeight: FontWeight.bold,
                      color: isOn ? Colors.white : const Color(0xFF831843),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${fLeds.length} p | ${isOn ? "BẬT" : "TẮT"}',
                    style: TextStyle(
                      fontSize: isPhone ? 7.0 : 8.5,
                      fontWeight: isOn ? FontWeight.bold : FontWeight.w600,
                      color: isOn ? Colors.yellow.shade100 : const Color(0xFF9D174D),
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