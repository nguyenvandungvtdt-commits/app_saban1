// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io'; // 🟢 Cần thiết để sử dụng File(path).existsSync()
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/websocket_service.dart';
// import '../widgets/dynamic_image.dart';
// import '../services/config_service.dart';
// import '../widgets/interactive_image_viewer.dart';
// import '../services/image_resolver.dart'; // 🟢 BỔ SUNG IMPORT NÀY (sửa lại đường dẫn tương đối nếu khác thư mục)
// class RoomsListScreen extends StatefulWidget {
//   final Map<String, dynamic>? configData;
//   final String floorName;
//   final String? buildingName; // 🟢 THÊM DÒNG NÀY (Định danh tòa nhà để ghép key SharedPreferences)
//   final List<dynamic> rooms;
//   final Map<int, bool> ledStates;
//   final Function(List<int> leds, bool state) onToggleLeds;
//   final bool Function(List<int> leds) isAnyLedOn;
//   final String? roomImageConfig;
//   final String currentLang; // 🟢 Thêm thuộc tính lưu ngôn ngữ
//   const RoomsListScreen({
//     super.key,
//     required this.floorName,
//     this.buildingName, // 🟢 THÊM DÒNG NÀY
//     required this.rooms,
//     required this.ledStates,
//     required this.onToggleLeds,
//     required this.isAnyLedOn,
//     this.roomImageConfig,
//     this.configData,
//     this.currentLang = 'vi', // 🟢 Mặc định tiếng Việt nếu không truyền
//   });
//   @override
//   State<RoomsListScreen> createState() => _RoomsListScreenState();
// }
// class _RoomsListScreenState extends State<RoomsListScreen>
//     with SingleTickerProviderStateMixin {
//   int? _extractRoomNumber(String roomTitle) {
//     final RegExp regExp = RegExp(r'\d+');
//     final match = regExp.firstMatch(roomTitle);
//     if (match != null) {
//       return int.tryParse(match.group(0)!);
//     }
//     return null;
//   }
//   bool _isRoomInInputRange({
//     required String roomTitle,
//     required int roomIndex, // Vị trí phòng (bắt đầu từ 1)
//     required List<int> targetRange,
//   }) {
//     if (targetRange.isEmpty) return false;
//     if (targetRange.contains(roomIndex)) {
//       return true;
//     }
//     int? extractedNumber = _extractRoomNumber(roomTitle);
//     if (extractedNumber != null && targetRange.contains(extractedNumber)) {
//       return true;
//     }
//     return false;
//   }
//   List<int> _parseRoomRangeInput(String input) {
//     List<int> targetRooms = [];
//     String trimmed = input.trim();
//     if (trimmed.isEmpty) return targetRooms;
//     List<String> segments = trimmed.split(',');
//     for (String segment in segments) {
//       String part = segment.trim();
//       if (part.isEmpty) continue;
//       if (part.contains('-')) {
//         List<String> bounds = part.split('-');
//         if (bounds.length == 2) {
//           int? start = int.tryParse(bounds[0].trim());
//           int? end = int.tryParse(bounds[1].trim());
//           if (start != null && end != null) {
//             if (start <= end) {
//               for (int i = start; i <= end; i++) {
//                 targetRooms.add(i);
//               }
//             } else {
//               for (int i = start; i >= end; i--) {
//                 targetRooms.add(i);
//               }
//             }
//           }
//         }
//       } else {
//         int? single = int.tryParse(part);
//         if (single != null) {
//           targetRooms.add(single);
//         }
//       }
//     }
//     return targetRooms.toSet().toList();
//   }
//   final TransformationController _transformationController =
//       TransformationController();
//   late AnimationController _animationController;
//   Animation<Matrix4>? _animation;
//   String?
//   _activeRoomTitle; // 🟢 Để null mặc định để khi mở màn hình sẽ hiện Ảnh Tầng
//   String? _currentRoomImageUrl; // 🟢 THÊM DÒNG NÀY VÀO ĐÂY
//   Map<String, dynamic> _cachedRoomLayouts = {};
//   void _resetZoomAndExecute(VoidCallback onComplete) {
//     if (!_transformationController.value.isIdentity()) {
//       _animation =
//           Matrix4Tween(
//             begin: _transformationController.value,
//             end: Matrix4.identity(),
//           ).animate(
//             CurvedAnimation(
//               parent: _animationController,
//               curve: Curves.easeOut,
//             ),
//           );
//       _animationController.forward(from: 0).then((_) {
//         onComplete(); // 🟢 Chuyển trang sau khi thu nhỏ xong
//       });
//     } else {
//       onComplete(); // 🟢 Nếu ảnh chưa zoom -> Chuyển trang luôn lập tức!
//     }
//     ConfigService.getRoomLayouts().then((layouts) {
//       if (mounted) {
//         setState(() {
//           _cachedRoomLayouts = layouts;
//         });
//       }
//     });
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _precacheRoomLayouts();
//     });
//   }
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _transformationController.dispose();
//     super.dispose();
//   }
//   String removeVietnameseDiacritics(String str) {
//     var withDiacritics =
//         'àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
//     var withoutDiacritics =
//         'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
//     String result = str;
//     for (int i = 0; i < withDiacritics.length; i++) {
//       result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
//       result = result.replaceAll(
//         withDiacritics[i].toUpperCase(),
//         withoutDiacritics[i].toUpperCase(),
//       );
//     }
//     return result;
//   }
//   String _getLayoutCategoryKey(String roomName) {
//     if (roomName.isEmpty) return 'ROOM';
//     String cleanName = roomName.trim().toUpperCase();
//     for (String key in _cachedRoomLayouts.keys) {
//       if (key.isNotEmpty &&
//           (cleanName == key ||
//               cleanName.contains(key) ||
//               key.contains(cleanName))) {
//         return key;
//       }
//     }
//     return cleanName;
//   }
//   bool get _isEn => widget.currentLang == 'en';
//   String _currentFloorName = '';
//   String? _overrideFloorImagePath;
//   Map<String, String> _overrideRoomLayouts = {};
//   final ImagePicker _imagePicker = ImagePicker();
//   @override
//   @override
//   void initState() {
//     super.initState();
//     _animationController =
//         AnimationController(
//           vsync: this,
//           duration: const Duration(milliseconds: 250),
//         )..addListener(() {
//           if (_animation != null) {
//             _transformationController.value = _animation!.value;
//           }
//         });
//     _currentFloorName = widget.floorName;
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     _loadLocalImageOverrides();
//   }
//   String _getStorageKey(String floorTitle) {
//     String bName = widget.buildingName ?? '';
//     return 'saved_floor_image_${bName}_$floorTitle';
//   }
//   Future<void> _loadLocalImageOverrides() async {
//     final prefs = await SharedPreferences.getInstance();
//     String bName = widget.buildingName ?? '';
//     String fName = widget.floorName;
//     String floorKey = _getStorageKey(fName);
//     String? savedFloorImg = prefs.getString(floorKey);
//     String activeFloorImagePath;
//     if (savedFloorImg != null && savedFloorImg.isNotEmpty) {
//       activeFloorImagePath = savedFloorImg;
//       debugPrint('🏢 [ROOM SCREEN] Dùng ảnh Tầng Custom: $savedFloorImg');
//     } else if (widget.roomImageConfig != null &&
//         widget.roomImageConfig!.isNotEmpty) {
//       activeFloorImagePath = widget.roomImageConfig!;
//       debugPrint(
//         '🏢 [ROOM SCREEN] Dùng ảnh Tầng Config: ${widget.roomImageConfig}',
//       );
//     } else {
//       activeFloorImagePath = 'assets/images/default_floor.jpg';
//       debugPrint(
//         '🏢 [ROOM SCREEN] Dùng ảnh Tầng mặc định: assets/images/default_floor.jpg',
//       );
//     }
//     Map<String, String> loadedRoomLayouts = {};
//     for (var r in widget.rooms) {
//       String rName = r['room_number'] ?? r['name'] ?? '';
//       if (rName.isNotEmpty) {
//         String roomKey = 'custom_room_layout_${bName}_$rName';
//         String? savedRoomImg = prefs.getString(roomKey);
//         if (savedRoomImg != null && savedRoomImg.isNotEmpty) {
//           loadedRoomLayouts[rName] = savedRoomImg;
//         }
//       }
//     }
//     if (mounted) {
//       setState(() {
//         _overrideFloorImagePath = activeFloorImagePath;
//         _overrideRoomLayouts = loadedRoomLayouts;
//         _currentRoomImageUrl = activeFloorImagePath;
//       });
//     }
//   }
//   String _getRoomImagePath(String roomName, String defaultFloorPath) {
//     if (_overrideRoomLayouts.containsKey(roomName) &&
//         _overrideRoomLayouts[roomName]!.isNotEmpty) {
//       return _overrideRoomLayouts[roomName]!;
//     }
//     return 'assets/images/default_room.jpg';
//   }
//   void _precacheRoomLayouts() async {
//   if (!mounted) return;
//   final Stopwatch stopwatch = Stopwatch()..start();
//   debugPrint('🚀 [PRECACHE START] Bắt đầu nạp đệm danh sách ảnh local...');
//   try {
//     final Map<String, dynamic> roomLayoutsMap = _cachedRoomLayouts.isNotEmpty
//         ? _cachedRoomLayouts
//         : (widget.configData?['room_layouts'] as Map<String, dynamic>? ?? {});
//     if (roomLayoutsMap.isEmpty) {
//       debugPrint('⚠️ [PRECACHE CANCEL] Danh sách room_layouts bị RỖNG!');
//       return;
//     }
//     final String projectId = widget.configData?['project_id'] ??
//         await ConfigService.getActiveProjectId();
//     final precacheTasks = roomLayoutsMap.entries.map((entry) async {
//       final String rawKey = entry.key.toString();
//       final String defaultValue = entry.value.toString();
//       final String layoutKey = 'room_${rawKey.toLowerCase()}';
//       if (defaultValue.isEmpty) return;
//       final String imagePath = await ImageResolver.getActiveImagePath(
//         projectId: projectId,
//         imageKey: layoutKey,
//         cloudUrl: defaultValue,
//       );
//       if (imagePath.startsWith('assets/')) {
//         if (!mounted) return;
//         await precacheImage(
//           AssetImage(imagePath),
//           context, // Truy cập State.context
//         ).catchError((_) {});
//       } else {
//         final file = File(imagePath);
//         final bool fileExists = await file.exists();
//         if (!mounted || !fileExists) return;
//         await precacheImage(
//           FileImage(file),
//           context, // Truy cập State.context
//         ).catchError((_) {});
//       }
//     });
//     await Future.wait(precacheTasks);
//     stopwatch.stop();
//     debugPrint(
//       '✅ [PRECACHE FINISHED] Nạp xong toàn bộ ${roomLayoutsMap.length} ảnh vào RAM trong: ${stopwatch.elapsedMilliseconds} ms',
//     );
//   } catch (e) {
//     debugPrint('⚠️ [PRECACHE ERROR] $e');
//   }
// }
//   @override
//   void didUpdateWidget(covariant RoomsListScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.configData != oldWidget.configData &&
//         widget.configData != null &&
//         widget.configData!.containsKey('room_layouts')) {
//       setState(() {
//         _cachedRoomLayouts = Map<String, dynamic>.from(
//           widget.configData!['room_layouts'],
//         );
//       });
//       debugPrint(
//         '🔄 [UPDATED] Đã cập nhật lại _cachedRoomLayouts do configData thay đổi!',
//       );
//     }
//   }
//   String getRoomLayoutPath(
//     String roomName,
//     Map<String, dynamic>? configData,
//     String defaultFloorImg,
//   ) {
//     if (roomName.isEmpty) return defaultFloorImg;
//     String cleanName = roomName.trim().toUpperCase();
//     String categoryKey = _getLayoutCategoryKey(cleanName);
//     if (_overrideRoomLayouts.containsKey(categoryKey) &&
//         _overrideRoomLayouts[categoryKey]!.isNotEmpty) {
//       return _overrideRoomLayouts[categoryKey]!;
//     }
//     if (_overrideRoomLayouts.containsKey(roomName) &&
//         _overrideRoomLayouts[roomName]!.isNotEmpty) {
//       return _overrideRoomLayouts[roomName]!;
//     }
//     if (configData != null && configData.containsKey('custom_room_images')) {
//       Map<String, dynamic> customImages = configData['custom_room_images'];
//       if (customImages.containsKey(roomName) &&
//           customImages[roomName].toString().isNotEmpty) {
//         return customImages[roomName].toString();
//       }
//     }
//     if (_cachedRoomLayouts.containsKey(categoryKey) &&
//         _cachedRoomLayouts[categoryKey].toString().trim().isNotEmpty) {
//       return _cachedRoomLayouts[categoryKey].toString();
//     }
//     return defaultFloorImg;
//   }
//   Map<String, String> _getRoomInfoDetails(
//     String roomName,
//     Map<String, dynamic>? configData,
//   ) {
//     String cleanName = roomName.trim().toUpperCase();
//     Map<String, dynamic> customInfos = configData?['custom_room_info'] ?? {};
//     if (customInfos.containsKey(roomName)) {
//       var info = customInfos[roomName];
//       return {
//         'Area': info['area'] ?? '68.5 m²',
//         'Type': info['type'] ?? '2 Bedroom',
//         'Balcony': info['balcony'] ?? 'South-East',
//         'Status': info['status'] ?? 'Available',
//       };
//     }
//     if (cleanName.contains('2BR') || cleanName.contains('2PN')) {
//       return {
//         'Area': '65 - 72 m²',
//         'Type': '2 Bedrooms + 2 WC',
//         'View': 'City & Swimming Pool View',
//       };
//     }
//     if (cleanName.contains('3BR') || cleanName.contains('3PN')) {
//       return {
//         'Area': '88 - 105 m²',
//         'Type': '3 Bedrooms + 2 WC',
//         'View': 'River & Park View',
//       };
//     }
//     if (cleanName.contains('SHOPHOUSE') || cleanName.contains('SHOUSE')) {
//       return {
//         'Area': '120 - 180 m²',
//         'Type': 'Duplex Commercial Shophouse',
//         'View': 'Main Street Frontage',
//       };
//     }
//     return {
//       'Area': 'Public Amenity',
//       'Type': 'Shared Facility',
//       'Access': '24/7 Residents Only',
//     };
//   }
//   void _handleRoomTap(String roomName, int ledIdx) {
//     bool isOn = widget.isAnyLedOn([ledIdx]);
//     bool newState = !isOn;
//     widget.ledStates[ledIdx] = newState;
//     widget.onToggleLeds([ledIdx], newState);
//     if (WebSocketService().isConnected) {
//       WebSocketService().sendSingleRoom(ledIdx, newState);
//     }
//     String targetRoomName = roomName;
//     if (!newState) {
//       String? nextActiveRoom;
//       for (var room in widget.rooms.reversed) {
//         int rLed =
//             int.tryParse(
//               '${room['led_index'] ?? room['hardwareIndex'] ?? 0}',
//             ) ??
//             0;
//         String rName = room['room_number'] ?? room['name'] ?? '';
//         if (widget.isAnyLedOn([rLed]) && rName != roomName) {
//           nextActiveRoom = rName;
//           break;
//         }
//       }
//       targetRoomName = nextActiveRoom ?? '';
//     }
//     String defaultFloorPath =
//         _overrideFloorImagePath ??
//         widget.roomImageConfig ??
//         'assets/images/default_room.jpg';
//     String finalPath = targetRoomName.isNotEmpty
//         ? _getRoomImagePath(targetRoomName, defaultFloorPath)
//         : defaultFloorPath;
//     debugPrint('==================== [DEBUG TAP ROOM] ====================');
//     debugPrint(
//       '👉 Căn hộ vừa bấm: "$roomName" | LED #$ledIdx | Trạng thái: ${newState ? "ON (BẬT)" : "OFF (TẮT)"}',
//     );
//     debugPrint(
//       '🎯 Căn hộ hiển thị chính: "${targetRoomName.isEmpty ? "SA BÀN TẦNG" : targetRoomName}"',
//     );
//     debugPrint('🏢 Ảnh Sa bàn Tầng active: "$defaultFloorPath"');
//     debugPrint('🖼️ Đường dẫn ảnh render: "$finalPath"');
//     debugPrint('==========================================================');
//     if (mounted) {
//       setState(() {
//         _activeRoomTitle = targetRoomName.isEmpty ? null : targetRoomName;
//         _currentRoomImageUrl = finalPath;
//       });
//     }
//   }
//   List<List<dynamic>> _chunkRooms(List<dynamic> list, int itemsPerRow) {
//     List<List<dynamic>> chunks = [];
//     for (int i = 0; i < list.length; i += itemsPerRow) {
//       int end = (i + itemsPerRow < list.length) ? i + itemsPerRow : list.length;
//       chunks.add(list.sublist(i, end));
//     }
//     return chunks;
//   }
//   @override
//   Widget build(BuildContext context) {
//     Map<String, dynamic>? configMap = widget.configData;
//     final bool showRoomInfo = configMap?['settings']?['show_room_info'] ?? true;
//     String defaultFloorPath =
//         widget.roomImageConfig ?? 'assets/images/room.jpg';
//     String activeFloorPath =
//         (_overrideFloorImagePath != null && _overrideFloorImagePath!.isNotEmpty)
//         ? _overrideFloorImagePath!
//         : defaultFloorPath;
//     final String currentImagePath =
//         (_currentRoomImageUrl != null && _currentRoomImageUrl!.isNotEmpty)
//         ? _currentRoomImageUrl!
//         : activeFloorPath;
//     Map<String, String>? activeRoomInfo = _activeRoomTitle != null
//         ? _getRoomInfoDetails(_activeRoomTitle!, configMap)
//         : null;
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Positioned.fill(
//             child: DynamicImage(
//               imagePath: currentImagePath,
//               fit: BoxFit.cover,
//               fallbackAsset: 'assets/images/room.jpg',
//             ),
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
//                       const Color(0xFFF0F9FF).withValues(alpha: 0.88),
//                       const Color(0xFFE0F2FE).withValues(alpha: 0.82),
//                       const Color(0xFFF8FAFC).withValues(alpha: 0.92),
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
//                     _buildTopBar(context, activeFloorPath),
//                     Expanded(
//                       child: Padding(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: isPhone ? 12.0 : 16.0,
//                           vertical: isPhone ? 4.0 : 8.0,
//                         ),
//                         child: Center(
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 200),
//                             child: GestureDetector(
//                               key: ValueKey(
//                                 'gesture_room_${_activeRoomTitle}_$currentImagePath',
//                               ),
//                               behavior: HitTestBehavior.opaque,
//                               onHorizontalDragStart: (details) {},
//                               onHorizontalDragUpdate: (details) {},
//                               onHorizontalDragEnd: (details) {
//                                 double velocity = details.primaryVelocity ?? 0;
//                                 if (velocity > 150) {
//                                   if (Navigator.canPop(context)) {
//                                     _resetZoomAndExecute(() {
//                                       Navigator.pop(context);
//                                     });
//                                   }
//                                 }
//                               },
//                               child: Container(
//                                 key: ValueKey(
//                                   '${_activeRoomTitle}_$currentImagePath',
//                                 ),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(0xFF0284C7)
//                                           .withValues(alpha: 0.22),
//                                       blurRadius: 24,
//                                       spreadRadius: 1,
//                                       offset: const Offset(0, 8),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(20),
//                                   child: Stack(
//                                     children: [
//                                       InteractiveImageViewer(
//                                         key: ValueKey(
//                                           'img_${_activeRoomTitle}_$currentImagePath',
//                                         ),
//                                         imagePath: currentImagePath,
//                                         borderRadius: 20.0,
//                                       ),
//                                       if (_activeRoomTitle != null &&
//                                           activeRoomInfo != null &&
//                                           showRoomInfo)
//                                         Positioned(
//                                           top: 12,
//                                           left: 12,
//                                           child: ClipRRect(
//                                             borderRadius: BorderRadius.circular(
//                                               14,
//                                             ),
//                                             child: BackdropFilter(
//                                               filter: ImageFilter.blur(
//                                                 sigmaX: 12,
//                                                 sigmaY: 12,
//                                               ),
//                                               child: Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 14,
//                                                       vertical: 10,
//                                                     ),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.black
//                                                       .withValues(alpha: 0.55),
//                                                   borderRadius:
//                                                       BorderRadius.circular(14),
//                                                   border: Border.all(
//                                                     color: Colors.white
//                                                         .withValues(
//                                                           alpha: 0.25,
//                                                         ),
//                                                     width: 1,
//                                                   ),
//                                                 ),
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   mainAxisSize:
//                                                       MainAxisSize.min,
//                                                   children: [
//                                                     Row(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         const Icon(
//                                                           Icons.sensor_door,
//                                                           color: Color(
//                                                             0xFF38BDF8,
//                                                           ),
//                                                           size: 16,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 6,
//                                                         ),
//                                                         Text(
//                                                           _activeRoomTitle!,
//                                                           style:
//                                                               const TextStyle(
//                                                                 color: Colors
//                                                                     .white,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 fontSize: 13,
//                                                               ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 6),
//                                                     ...activeRoomInfo.entries.map(
//                                                       (e) => Padding(
//                                                         padding:
//                                                             const EdgeInsets.only(
//                                                               top: 2.0,
//                                                             ),
//                                                         child: Text(
//                                                           '• ${e.key.toUpperCase()}: ${e.value}',
//                                                           style: TextStyle(
//                                                             color: Colors.white
//                                                                 .withValues(
//                                                                   alpha: 0.88,
//                                                                 ),
//                                                             fontSize: 10.5,
//                                                             fontWeight:
//                                                                 FontWeight.w500,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
//                       child: _buildAdaptiveRoomPanel(context, isPhone),
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
//   Widget _buildTopBar(BuildContext context, String defaultFloorPath) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.white.withValues(alpha: 0.85),
//             child: IconButton(
//               icon: const Icon(
//                 Icons.arrow_back_ios_new,
//                 color: Color(0xFF0369A1),
//                 size: 18,
//               ),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           const SizedBox(width: 8),
//           CircleAvatar(
//             backgroundColor: Colors.white.withValues(alpha: 0.85),
//             child: IconButton(
//               tooltip: _isEn ? 'Manage Room Images' : 'Quản lý ảnh các căn hộ',
//               icon: const Icon(
//                 Icons.edit_note_rounded,
//                 color: Color(0xFF0369A1),
//                 size: 22,
//               ),
//               onPressed: () => _showQuickEditRoomDialog(
//                 context,
//               ), // 🟢 Gọi Dialog Menu 3 gạch
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   void _showQuickEditRoomDialog(BuildContext context) {
//     final TextEditingController rangeController = TextEditingController();
//     String rangePreviewImage = '';
//     String errorMsg = '';
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return DefaultTabController(
//           length: 2,
//           child: StatefulBuilder(
//             builder: (context, setDialogState) {
//               return AlertDialog(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 title: Column(
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.collections_bookmark_rounded,
//                           color: Color(0xFF0369A1),
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           _isEn
//                               ? 'Manage Room Images'
//                               : 'Quản Lý Ảnh Các Căn Hộ',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     TabBar(
//                       labelColor: const Color(0xFF0284C7),
//                       unselectedLabelColor: Colors.grey,
//                       indicatorColor: const Color(0xFF0284C7),
//                       tabs: [
//                         Tab(
//                           icon: const Icon(
//                             Icons.dynamic_feed_rounded,
//                             size: 20,
//                           ),
//                           text: _isEn ? 'By Range' : 'Theo Dải Phòng',
//                         ),
//                         Tab(
//                           icon: const Icon(
//                             Icons.format_list_bulleted_rounded,
//                             size: 20,
//                           ),
//                           text: _isEn ? 'All Rooms' : 'Tất Cả Phòng',
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 content: SizedBox(
//                   width: double.maxFinite,
//                   height: 390,
//                   child: TabBarView(
//                     children: [
//                       SingleChildScrollView(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const SizedBox(height: 10),
//                             Text(
//                               _isEn
//                                   ? 'Apply 1 image for multiple rooms:'
//                                   : 'Áp dụng 1 ảnh cho nhiều phòng đồng dạng:',
//                               style: const TextStyle(
//                                 fontSize: 12.5,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             TextField(
//                               controller: rangeController,
//                               decoration: InputDecoration(
//                                 labelText: _isEn
//                                     ? 'Room Range (e.g. 1-5 or 101-108 or 1-5,10 )'
//                                     : 'Dải phòng (Ví dụ: 1-5 hoặc 101-108 hoặc 1-5,10)',
//                                 prefixIcon: const Icon(Icons.numbers_rounded),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 hintText: '101-108',
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Container(
//                               height: 120,
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 color: Colors.black12,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: Colors.grey.shade300),
//                               ),
//                               clipBehavior: Clip.antiAlias,
//                               child: rangePreviewImage.isNotEmpty
//                                   ? (rangePreviewImage.startsWith('assets/')
//                                         ? Image.asset(
//                                             rangePreviewImage,
//                                             key: ValueKey(
//                                               'room_preview_$rangePreviewImage',
//                                             ),
//                                             fit: BoxFit.contain,
//                                           )
//                                         : Image.file(
//                                             File(rangePreviewImage),
//                                             key: ValueKey(
//                                               'room_preview_$rangePreviewImage',
//                                             ),
//                                             fit: BoxFit.contain,
//                                           ))
//                                   : const Center(
//                                       child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Icon(
//                                             Icons.image_outlined,
//                                             size: 36,
//                                             color: Colors.grey,
//                                           ),
//                                           SizedBox(height: 4),
//                                           Text(
//                                             'Chưa chọn ảnh cho dải phòng',
//                                             style: TextStyle(
//                                               fontSize: 11,
//                                               color: Colors.grey,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                             ),
//                             const SizedBox(height: 10),
//                             SizedBox(
//                               width: double.infinity,
//                               child: OutlinedButton.icon(
//                                 onPressed: () async {
//                                   final XFile? image = await _imagePicker
//                                       .pickImage(
//                                         source: ImageSource.gallery,
//                                         imageQuality: 85,
//                                       );
//                                   if (image != null) {
//                                     setDialogState(() {
//                                       rangePreviewImage = image.path;
//                                       errorMsg = '';
//                                     });
//                                     debugPrint(
//                                       '📸 [ROOM RANGE PICKER] Đã chọn ảnh dải phòng: ${image.path}',
//                                     );
//                                   }
//                                 },
//                                 icon: const Icon(Icons.photo_library),
//                                 label: Text(
//                                   _isEn
//                                       ? 'Choose Shared Image'
//                                       : 'Chọn Ảnh Dùng Chung',
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             if (errorMsg.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(bottom: 8.0),
//                                 child: Text(
//                                   errorMsg,
//                                   style: const TextStyle(
//                                     color: Colors.redAccent,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color(0xFF0284C7),
//                                       foregroundColor: Colors.white,
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 11,
//                                       ),
//                                     ),
//                                     icon: const Icon(
//                                       Icons.done_all_rounded,
//                                       size: 18,
//                                     ),
//                                     label: Text(
//                                       _isEn ? 'Apply Range' : 'Áp Dụng Dải',
//                                       style: const TextStyle(fontSize: 12),
//                                     ),
//                                     onPressed: () async {
//                                       String input = rangeController.text
//                                           .trim();
//                                       List<int> targetRooms =
//                                           _parseRoomRangeInput(input);
//                                       debugPrint(
//                                         '================ [DEBUG BULK ROOM RANGE APPLY] ================',
//                                       );
//                                       debugPrint(
//                                         '👉 Chuỗi nhập dải phòng: "$input"',
//                                       );
//                                       debugPrint(
//                                         '👉 Danh sách số/thứ tự mục tiêu: $targetRooms',
//                                       );
//                                       if (targetRooms.isEmpty) {
//                                         setDialogState(() {
//                                           errorMsg = '⚠️ Vui lòng nhập dải phòng hợp lệ (Ví dụ: 1-4 hoặc 101-108)!';
//                                         });
//                                         return;
//                                       }
//                                       if (rangePreviewImage.isEmpty) {
//                                         setDialogState(() {
//                                           errorMsg = '⚠️ Vui lòng nhấn "Chọn Ảnh Dùng Chung" trước!';
//                                         });
//                                         return;
//                                       }
//                                       final prefs =
//                                           await SharedPreferences.getInstance();
//                                       Map<String, String> updatedMap = {};
//                                       for (
//                                         int i = 0;
//                                         i < widget.rooms.length;
//                                         i++
//                                       ) {
//                                         var r = widget.rooms[i];
//                                         String rName =
//                                             r['room_number'] ?? r['name'] ?? '';
//                                         int displayIndex =
//                                             i + 1; // Thứ tự 1, 2, 3, 4...
//                                         bool isMatch = _isRoomInInputRange(
//                                           roomTitle: rName,
//                                           roomIndex: displayIndex,
//                                           targetRange: targetRooms,
//                                         );
//                                         debugPrint(
//                                           '🏠 [$displayIndex] Kiểm tra phòng "$rName" | Khớp dải: $isMatch',
//                                         );
//                                         if (isMatch && rName.isNotEmpty) {
//                                           String storageKey =
//                                               'custom_room_layout_${widget.buildingName ?? ''}_$rName';
//                                           await prefs.setString(
//                                             storageKey,
//                                             rangePreviewImage,
//                                           );
//                                           updatedMap[rName] = rangePreviewImage;
//                                           debugPrint(
//                                             '   ✅ [Đã gán ảnh mới] cho phòng "$rName" -> Key: $storageKey',
//                                           );
//                                         }
//                                       }
//                                       debugPrint(
//                                         '===============================================================',
//                                       );
//                                       imageCache.clear();
//                                       imageCache.clearLiveImages();
//                                       if (mounted) {
//                                         setState(() {
//                                           _overrideRoomLayouts.addAll(
//                                             updatedMap,
//                                           );
//                                           if (_activeRoomTitle != null &&
//                                               updatedMap.containsKey(
//                                                 _activeRoomTitle,
//                                               )) {
//                                             _currentRoomImageUrl =
//                                                 rangePreviewImage;
//                                           }
//                                         });
//                                       }
//                                       if (dialogContext.mounted) {
//                                         Navigator.pop(dialogContext);
//                                       }
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       ListView.separated(
//                         itemCount: widget.rooms.length,
//                         separatorBuilder: (_, _) => const Divider(height: 1),
//                         itemBuilder: (ctx, index) {
//                           final room = widget.rooms[index];
//                           String rName =
//                               room['room_number'] ??
//                               room['name'] ??
//                               'Phòng ${index + 1}';
//                           String defaultFloorPath =
//                               _overrideFloorImagePath ??
//                               widget.roomImageConfig ??
//                               'assets/images/room.jpg';
//                           String imgPath = _getRoomImagePath(
//                             rName,
//                             defaultFloorPath,
//                           );
//                           bool isCustomized = _overrideRoomLayouts.containsKey(
//                             rName,
//                           );
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 6.0),
//                             child: Row(
//                               children: [
//                                 ClipRRect(
//                                   borderRadius: BorderRadius.circular(6),
//                                   child: Container(
//                                     width: 50,
//                                     height: 40,
//                                     color: Colors.black12,
//                                     child: imgPath.startsWith('assets/')
//                                         ? Image.asset(
//                                             imgPath,
//                                             key: ValueKey(
//                                               'tab2_room_${rName}_${isCustomized}_$imgPath',
//                                             ),
//                                             fit: BoxFit.cover,
//                                           )
//                                         : Image.file(
//                                             File(imgPath),
//                                             key: ValueKey(
//                                               'tab2_room_${rName}_${isCustomized}_$imgPath',
//                                             ),
//                                             fit: BoxFit.cover,
//                                           ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Text(
//                                     rName,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.photo_library,
//                                     color: Color(0xFF0284C7),
//                                     size: 20,
//                                   ),
//                                   tooltip: 'Đổi ảnh căn hộ này',
//                                   onPressed: () async {
//                                     final XFile? image = await _imagePicker
//                                         .pickImage(
//                                           source: ImageSource.gallery,
//                                           imageQuality: 85,
//                                         );
//                                     if (image != null) {
//                                       final prefs =
//                                           await SharedPreferences.getInstance();
//                                       String storageKey =
//                                           'custom_room_layout_${widget.buildingName ?? ''}_$rName';
//                                       await prefs.setString(
//                                         storageKey,
//                                         image.path,
//                                       );
//                                       imageCache.clear();
//                                       imageCache.clearLiveImages();
//                                       if (mounted) {
//                                         setState(() {
//                                           _overrideRoomLayouts[rName] =
//                                               image.path;
//                                           if (_activeRoomTitle == rName) {
//                                             _currentRoomImageUrl = image.path;
//                                           }
//                                         });
//                                       }
//                                       setDialogState(() {});
//                                       debugPrint(
//                                         '✅ [SINGLE ROOM EDIT] Cập nhật ảnh phòng "$rName" -> ${image.path}',
//                                       );
//                                     }
//                                   },
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(dialogContext),
//                     child: Text(_isEn ? 'Close' : 'Đóng'),
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//   Widget _buildCompactRoomButton(dynamic room, bool isPhone) {
//     int ledIdx =
//         int.tryParse('${room['led_index'] ?? room['hardwareIndex'] ?? 0}') ?? 0;
//     bool isOn = widget.isAnyLedOn([ledIdx]);
//     String roomName = room['room_number'] ?? room['name'] ?? 'Room';
//     final bool isSelected =
//         _activeRoomTitle?.toLowerCase() == roomName.toLowerCase();
//     return InkWell(
//       onTap: () => _handleRoomTap(roomName, ledIdx),
//       onDoubleTap: () => _handleRoomTap(roomName, ledIdx),
//       borderRadius: BorderRadius.circular(10),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: EdgeInsets.symmetric(
//           horizontal: isPhone ? 2 : 8,
//           vertical: isPhone ? 6 : 8,
//         ),
//         decoration: BoxDecoration(
//           gradient: isOn
//               ? const LinearGradient(
//                   colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//               : const LinearGradient(
//                   colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(
//                     0xFF0284C7,
//                   ) // Viền xanh dương Cyan nổi bật khi Active
//                 : (isOn ? Colors.amberAccent : const Color(0xFFF472B6)),
//             width: isSelected
//                 ? 2.5
//                 : 1.2, // Tăng độ dầy viền lên 2.5px khi active
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(isPhone ? 2 : 4),
//               decoration: BoxDecoration(
//                 color: isOn
//                     ? Colors.white.withValues(alpha: 0.25)
//                     : const Color(0xFFF472B6).withValues(alpha: 0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isOn ? Icons.lightbulb : Icons.king_bed_outlined,
//                 size: isPhone ? 11 : 13,
//                 color: isOn ? Colors.white : const Color(0xFFDB2777),
//               ),
//             ),
//             SizedBox(width: isPhone ? 3 : 6),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       roomName,
//                       style: TextStyle(
//                         fontSize: isPhone ? 10.0 : 12.0,
//                         fontWeight: FontWeight.bold,
//                         color: isOn ? Colors.white : const Color(0xFF831843),
//                       ),
//                     ),
//                   ),
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       'LED #$ledIdx | ${isOn ? "ON" : "OFF"}',
//                       style: TextStyle(
//                         fontSize: isPhone ? 7.5 : 8.5,
//                         fontWeight: isOn ? FontWeight.bold : FontWeight.w600,
//                         color: isOn
//                             ? Colors.yellow.shade100
//                             : const Color(0xFF9D174D),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildAdaptiveRoomPanel(BuildContext context, bool isPhone) {
//     int itemsPerRow = isPhone ? 4 : 5;
//     List<List<dynamic>> roomRows = _chunkRooms(widget.rooms, itemsPerRow);
//     double spacing = isPhone ? 4.0 : 12.0;
//     dynamic activeRoomObj;
// bool isRoomSelected = _activeRoomTitle != null && _activeRoomTitle!.isNotEmpty;
// if (isRoomSelected) {
//   try {
//     activeRoomObj = widget.rooms.firstWhere(
//       (r) =>
//           (r['room_number'] ?? r['name'] ?? '').toString().toLowerCase() ==
//           _activeRoomTitle!.toLowerCase(),
//     );
//   } catch (_) {
//     activeRoomObj = null;
//   }
// }
// String activeDisplayTitle = isRoomSelected
//     ? (activeRoomObj != null 
//         ? (activeRoomObj['room_number'] ?? activeRoomObj['name'] ?? _activeRoomTitle!).toString().toUpperCase()
//         : _activeRoomTitle!.toUpperCase())
//     : _currentFloorName.toUpperCase();
//     List<int> allFloorRoomLeds = [];
//     bool isAnyRoomOn = false;
//     for (var r in widget.rooms) {
//       int ledIdx =
//           int.tryParse('${r['led_index'] ?? r['hardwareIndex'] ?? 0}') ?? 0;
//       allFloorRoomLeds.add(ledIdx);
//       if (widget.isAnyLedOn([ledIdx])) {
//         isAnyRoomOn = true; // Chỉ cần 1 căn hộ BẬT -> Master On
//       }
//     }
//     allFloorRoomLeds = allFloorRoomLeds.toSet().toList();
//     bool isFloorMasterOn = isAnyRoomOn;
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.layers, size: 18, color: Color(0xFF0284C7)),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Mặt bằng: $activeDisplayTitle',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF0369A1),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 4),
//         Container(
//           width: double.infinity,
//           padding: EdgeInsets.symmetric(
//             horizontal: isPhone ? 8 : 16,
//             vertical: isPhone ? 8 : 12,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white.withValues(alpha: 0.92),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF0284C7).withValues(alpha: 0.1),
//                 blurRadius: 18,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.tune,
//                     size: isPhone ? 13 : 15,
//                     color: const Color(0xFF0369A1),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     _isEn
//                         ? 'DIRECT ROOM CONTROL'
//                         : 'ĐIỀU KHIỂN CĂN HỘ TRỰC TIẾP',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF0369A1),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: isPhone ? 6 : 8),
//               InkWell(
//                 onTap: () {
//                   if (allFloorRoomLeds.isEmpty) return;
//                   bool targetState = !isFloorMasterOn;
//                   widget.onToggleLeds(allFloorRoomLeds, targetState);
//                   setState(() {
//                     if (!targetState) {
//                       _activeRoomTitle = null;
//                     }
//                   });
//                 },
//                 borderRadius: BorderRadius.circular(20),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 220),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isPhone ? 14 : 22,
//                     vertical: isPhone ? 5 : 7,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: isFloorMasterOn
//                         ? const LinearGradient(
//                             colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           )
//                         : const LinearGradient(
//                             colors: [Colors.white, Color(0xFFF0F9FF)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: isFloorMasterOn
//                           ? const Color(0xFFF43F5E)
//                           : const Color(0xFF0284C7),
//                       width: isFloorMasterOn ? 1.8 : 1.2,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: isFloorMasterOn
//                             ? const Color(0xFFEC4899).withValues(alpha: 0.45)
//                             : const Color(0xFF0284C7).withValues(alpha: 0.15),
//                         blurRadius: isFloorMasterOn ? 12 : 6,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(3),
//                         decoration: BoxDecoration(
//                           color: isFloorMasterOn
//                               ? Colors.white.withValues(alpha: 0.25)
//                               : const Color(0xFF0284C7).withValues(alpha: 0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           isFloorMasterOn
//                               ? Icons.lightbulb
//                               : Icons.lightbulb_outline,
//                           size: isPhone ? 13 : 15,
//                           color: isFloorMasterOn
//                               ? Colors.amberAccent
//                               : const Color(0xFF0284C7),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             isFloorMasterOn
//                                 ? (_isEn
//                                       ? 'TURN OFF ALL ROOMS'
//                                       : 'TẮT TỔNG TẦNG')
//                                 : (_isEn
//                                       ? 'TURN ON ALL ROOMS'
//                                       : 'BẬT TỔNG TẦNG'),
//                             style: TextStyle(
//                               fontSize: isPhone ? 10.5 : 12.0,
//                               fontWeight: FontWeight.bold,
//                               color: isFloorMasterOn
//                                   ? Colors.white
//                                   : const Color(0xFF0284C7),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           Text(
//                             '${allFloorRoomLeds.length} p | ${isFloorMasterOn ? (_isEn ? "ON" : "ĐANG BẬT") : (_isEn ? "OFF" : "ĐANG TẮT")}',
//                             style: TextStyle(
//                               fontSize: isPhone ? 8.0 : 9.0,
//                               fontWeight: FontWeight.w600,
//                               color: isFloorMasterOn
//                                   ? Colors.yellow.shade200
//                                   : const Color(0xFF0369A1),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: isPhone ? 8 : 10),
//               Column(
//                 children: roomRows.map((rowRooms) {
//                   return Padding(
//                     padding: EdgeInsets.only(bottom: isPhone ? 4 : 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: rowRooms.asMap().entries.map((entry) {
//                         int idx = entry.key;
//                         var room = entry.value;
//                         Widget item = _buildCompactRoomButton(room, isPhone);
//                         return isPhone
//                             ? Flexible(
//                                 fit: FlexFit.tight,
//                                 child: Padding(
//                                   padding: EdgeInsets.only(
//                                     right: idx == rowRooms.length - 1
//                                         ? 0
//                                         : spacing,
//                                   ),
//                                   child: item,
//                                 ),
//                               )
//                             : Padding(
//                                 padding: EdgeInsets.only(
//                                   right: idx == rowRooms.length - 1
//                                       ? 0
//                                       : spacing,
//                                 ),
//                                 child: SizedBox(width: 140.0, child: item),
//                               );
//                       }).toList(),
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 4),
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   _isEn
//                       ? '• 1-Tap: Toggle Light & View Layout'
//                       : '• Chạm 1 lần: Bật/Tắt Đèn & Hiển thị Layout',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: Color(0xFF0284C7),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // 🟢 Cần thiết để sử dụng File(path).existsSync()
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../widgets/dynamic_image.dart';
import '../services/config_service.dart';
import '../widgets/interactive_image_viewer.dart';
import '../services/image_resolver.dart'; // 🟢 BỔ SUNG IMPORT NÀY (sửa lại đường dẫn tương đối nếu khác thư mục)
// import 'package:image_picker/image_picker.dart';

class RoomsListScreen extends StatefulWidget {
  final Map<String, dynamic>? configData;
  final String floorName;
  final String? buildingName; // 🟢 THÊM DÒNG NÀY (Định danh tòa nhà để ghép key SharedPreferences)
  final List<dynamic> rooms;
  final Map<int, bool> ledStates;
  final Function(List<int> leds, bool state) onToggleLeds;
  final bool Function(List<int> leds) isAnyLedOn;
  final String? roomImageConfig;
  final String currentLang; // 🟢 Thêm thuộc tính lưu ngôn ngữ
  const RoomsListScreen({
    super.key,
    required this.floorName,
    this.buildingName, // 🟢 THÊM DÒNG NÀY
    required this.rooms,
    required this.ledStates,
    required this.onToggleLeds,
    required this.isAnyLedOn,
    this.roomImageConfig,
    this.configData,
    this.currentLang = 'vi', // 🟢 Mặc định tiếng Việt nếu không truyền
  });
  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}
class _RoomsListScreenState extends State<RoomsListScreen>
    with SingleTickerProviderStateMixin {
      final ImagePicker _imagePicker = ImagePicker(); // 👈 THÊM DÒNG NÀY
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
 String _getCategoryStorageKey(String categoryKey) {
  // CHỈ lưu prefix cố định + categoryKey (Rất quan trọng: Không ghép thêm widget.buildingName hay towerName)
  return 'custom_room_layout_$categoryKey';
}
  String?
  _activeRoomTitle; // 🟢 Để null mặc định để khi mở màn hình sẽ hiện Ảnh Tầng
  String? _currentRoomImageUrl; // 🟢 THÊM DÒNG NÀY VÀO ĐÂY
  Map<String, dynamic> _cachedRoomLayouts = {};
  void _resetZoomAndExecute(VoidCallback onComplete) {
    if (!_transformationController.value.isIdentity()) {
      _animation =
          Matrix4Tween(
            begin: _transformationController.value,
            end: Matrix4.identity(),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );
      _animationController.forward(from: 0).then((_) {
        onComplete(); // 🟢 Chuyển trang sau khi thu nhỏ xong
      });
    } else {
      onComplete(); // 🟢 Nếu ảnh chưa zoom -> Chuyển trang luôn lập tức!
    }
    ConfigService.getRoomLayouts().then((layouts) {
      if (mounted) {
        setState(() {
          _cachedRoomLayouts = layouts;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheRoomLayouts();
    });
  }
  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  String removeVietnameseDiacritics(String str) {
    var withDiacritics =
        'àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
    var withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    String result = str;
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
      result = result.replaceAll(
        withDiacritics[i].toUpperCase(),
        withoutDiacritics[i].toUpperCase(),
      );
    }
    return result;
  }

  bool get _isEn => widget.currentLang == 'en';
  String _currentFloorName = '';
  String? _overrideFloorImagePath;
  Map<String, String> _overrideRoomLayouts = {};
  // final ImagePicker _imagePicker = ImagePicker();
  @override
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
        });
    _currentFloorName = widget.floorName;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadLocalImageOverrides();
  }
  String _getStorageKey(String floorTitle) {
    String bName = widget.buildingName ?? '';
    return 'saved_floor_image_${bName}_$floorTitle';
  }
  // 🟢 1. BÓC TÁCH LOẠI PHÒNG DÙNG CHUNG TỪ FLAT_ROOMS VỚI DEBUGPRINT
 List<String> getDynamicRoomTypes(Map<String, dynamic>? configData) {
  debugPrint('🔍 [getDynamicRoomTypes] Bắt đầu bóc tách toàn bộ loại phòng từ JSON...');

  Set<String> categorySet = {};

  // Quét toàn bộ flat_rooms từ configData dự án
  if (configData != null && configData.containsKey('flat_rooms')) {
    List<dynamic> flatRooms = configData['flat_rooms'] ?? [];
    for (var item in flatRooms) {
      if (item is List && item.length >= 6) {
        String roomName = item[2].toString().trim();
        String description = item[5].toString().trim();

        String category = _extractCategoryFromInfo(roomName, description);
        if (category.isNotEmpty) {
          categorySet.add(category);
        }
      }
    }
  }

  // Chuyển Set thành List và sắp xếp cho đẹp mắt
  List<String> resultList = categorySet.toList();
  
  // Nối thêm nhóm mặc định nếu danh sách rỗng
  if (resultList.isEmpty) {
    resultList = ['Tất cả phòng'];
  }

  debugPrint('✅ [getDynamicRoomTypes] Danh sách loại phòng chuẩn (${resultList.length}): $resultList');
  return resultList;
}
String _extractCategoryFromInfo(String roomName, String description) {
  String rName = roomName.trim();
  String desc = description.trim();

  // 1. Ưu tiên 1: Tách Prefix nếu tên phòng có dấu '_' (VD: BỂ BƠI_B -> BỂ BƠI, CO WORKING_A -> CO WORKING)
  if (rName.contains('_')) {
    String prefix = rName.split('_').first.trim();
    bool isApartmentCode = RegExp(r'^[A-Z]{1,2}\d+', caseSensitive: false).hasMatch(prefix);

    if (prefix.isNotEmpty && !isApartmentCode && !RegExp(r'^\d+$').hasMatch(prefix)) {
      return prefix;
    }
  }

  // 2. Ưu tiên 2: Lấy loại căn từ Cột Description nếu có dấu '|' (VD: "Căn hộ 2 Phòng ngủ | ...")
  if (desc.contains('|')) {
    String firstPart = desc.split('|').first.trim();
    // Bỏ qua nếu firstPart chứa các chữ chung chung như "Tiện ích & Dịch vụ nội khu"
    if (firstPart.isNotEmpty && 
        !firstPart.toLowerCase().contains('tiện ích') && 
        !firstPart.toLowerCase().contains('dịch vụ')) {
      return firstPart;
    }
  }

  // 3. Loại bỏ hoàn toàn các chuỗi tên chung chung nếu rơi vào rName hoặc Description
  String checkTarget = rName.isNotEmpty ? rName : desc;
  if (checkTarget.toLowerCase().contains('tiện ích') || 
      checkTarget.toLowerCase().contains('dịch vụ nội khu')) {
    return ''; // Bỏ qua không đưa vào danh sách Dialog
  }

  // 4. Bỏ qua các mã căn hộ lẻ thông thường (A301, B402...)
  bool isDirectRoomCode = RegExp(r'^[A-Z]{1,2}\d+', caseSensitive: false).hasMatch(rName);
  if (isDirectRoomCode) return '';

  return rName;
}

  // 🟢 2. TRA CỨU ĐƯỜNG DẪN ẢNH PHÒNG TỐI ƯU VỚI DEBUGPRINT
  String getRoomLayoutPath(
  String roomName, 
  String description, 
  Map<String, dynamic>? configData, 
  String defaultRoomPath,
) {
  debugPrint('==================== 🖼️ [DEBUG GET ROOM LAYOUT] ====================');
  debugPrint('👉 Tap vào phòng: "$roomName" | Description: "$description"');

  // 1. UƯ TIÊN 1: Tìm chính xác theo tên phòng
  if (_overrideRoomLayouts.containsKey(roomName)) {
    String path = _overrideRoomLayouts[roomName]!;
    if (path.isNotEmpty && File(path).existsSync()) {
      debugPrint('🎯 [PRIORITY 1 OK] Tìm thấy ảnh riêng cho phòng "$roomName" -> Path: $path');
      return path;
    }
  }

  // 2. Bóc tách Category
  String categoryKey = _extractCategoryFromInfo(roomName, description);
  debugPrint('🔍 [EXTRACT CATEGORY] Bóc tách ra categoryKey: "$categoryKey"');

  if (categoryKey.isNotEmpty) {
    // 2.1. Tra cứu trực tiếp theo categoryKey chính xác
    if (_overrideRoomLayouts.containsKey(categoryKey)) {
      String path = _overrideRoomLayouts[categoryKey]!;
      if (path.isNotEmpty && File(path).existsSync()) {
        debugPrint('✅ [PRIORITY 2 OK] Khớp ảnh nhóm "$categoryKey" -> Path: $path');
        return path;
      }
    }

    // 2.2. Tra cứu mềm (Soft Match): Nếu categoryKey là "Shophouse", tìm key có chứa "Shophouse" trong _overrideRoomLayouts
    for (String key in _overrideRoomLayouts.keys) {
      if (key.toLowerCase().contains(categoryKey.toLowerCase()) || 
          categoryKey.toLowerCase().contains(key.toLowerCase())) {
        String path = _overrideRoomLayouts[key]!;
        if (path.isNotEmpty && File(path).existsSync()) {
          debugPrint('✅ [PRIORITY 2 SOFT-MATCH OK] Khớp mềm nhóm "$categoryKey" với Key Prefs "$key" -> Path: $path');
          return path;
        }
      }
    }
  }

  debugPrint('📌 [FALLBACK] Dùng ảnh phòng mặc định -> Path: $defaultRoomPath');
  debugPrint('===================================================================');
  
  return defaultRoomPath;
}
  // 🟢 3. DIALOG BẤM NÚT MENU 3 GẠCH CHO PHÉP ĐỔI ẢNH THEO LOẠI CĂN HOẶC PHÒNG LẺ
  void _showQuickEditRoomDialog(BuildContext context) {
  debugPrint('==================== 🖼️ [DIALOG OPEN] ====================');
  debugPrint('=== [DEBUG] Bấm mở Dialog Quản lý ảnh phòng ===');
  
  final List<String> dynamicRoomTypes = getDynamicRoomTypes(widget.configData);
  debugPrint('📊 [DIALOG INIT] Tổng số loại phòng bóc tách: ${dynamicRoomTypes.length}');
  debugPrint('📋 [DIALOG INIT] Danh sách loại phòng: $dynamicRoomTypes');
  debugPrint('🏢 [DIALOG INIT] Tổng số phòng lẻ trong tầng: ${widget.rooms.length}');
  debugPrint('===========================================================');

  showDialog(
    context: context,
    builder: (dialogContext) {
      return DefaultTabController(
        length: 2,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF0369A1)),
                      const SizedBox(width: 8),
                      Text(
                        _isEn ? 'Manage Room Images' : 'Quản Lý Ảnh Căn Hộ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    labelColor: const Color(0xFF0284C7),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF0284C7),
                    tabs: [
                      Tab(icon: const Icon(Icons.category_rounded, size: 20), text: _isEn ? 'By Type' : 'Theo Loại Căn'),
                      Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 20), text: _isEn ? 'All Rooms' : 'Tất Cả Phòng'),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 390,
                child: TabBarView(
                  children: [
                    // =========================================================================
                    // TAB 1: THAY ĐỔI ẢNH THEO LOẠI CĂN / TIỆN ÍCH DÙNG CHUNG
                    // =========================================================================
                    ListView.separated(
                      itemCount: dynamicRoomTypes.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        String typeKey = dynamicRoomTypes[index];
                        String defaultRoomPath = widget.roomImageConfig ?? 'assets/images/default_room.jpg';

                        // Gọi getRoomLayoutPath đúng 4 tham số
                        String imgPath = getRoomLayoutPath(
                          typeKey,           // 1. roomName (String)
                          '',                // 2. description (String - để rỗng vì typeKey đã là tên loại căn)
                          widget.configData, // 3. configData (Map<String, dynamic>?)
                          defaultRoomPath,   // 4. defaultRoomPath (String)
                        );

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 50,
                              height: 40,
                              color: Colors.black12,
                              child: imgPath.startsWith('assets/')
                                  ? Image.asset(imgPath, fit: BoxFit.cover)
                                  : Image.file(File(imgPath), fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(typeKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: const Text('Đổi ảnh cho tất cả vị trí cùng loại này', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.photo_library, color: Color(0xFF0284C7), size: 22),
                            tooltip: 'Đổi ảnh loại căn',
                            onPressed: () async {
  debugPrint('🖼️ [TAB 1 PICKER] Bấm chọn ảnh đại diện cho Loại Căn: "$typeKey"');
  final XFile? image = await _imagePicker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (image != null) {
    final prefs = await SharedPreferences.getInstance();
    
    // Ghi key chuẩn không dính tên tháp
    String storageKey = _getCategoryStorageKey(typeKey); 
    await prefs.setString(storageKey, image.path);
    debugPrint('💾 [SAVE PREFS TAB 1] Đã lưu nhóm "$storageKey" -> Path: ${image.path}');

    imageCache.clear();
    imageCache.clearLiveImages();

    if (mounted) {
      setState(() {
        // Cập nhật State với đúng key "typeKey"
        _overrideRoomLayouts[typeKey] = image.path;
      });
    }
    setDialogState(() {});
  }
},
                          ),
                        );
                      },
                    ),

                    // =========================================================================
                    // TAB 2: DANH SÁCH CHI TIẾT TỪNG PHÒNG LẺ
                    // =========================================================================
                    ListView.separated(
                      itemCount: widget.rooms.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final room = widget.rooms[index];
                        
                        // Bóc tách tên và description chuẩn của từng phòng lẻ
                        String rName = room['room_number'] ?? room['name'] ?? room['roomName'] ?? 'Phòng ${index + 1}';
                        String rDesc = room['description'] ?? '';
                        String defaultRoomPath = widget.roomImageConfig ?? 'assets/images/default_room.jpg';

                        // Tra cứu ảnh hiển thị cho chính phòng lẻ này với 4 tham số chuẩn
                        String imgPath = getRoomLayoutPath(
                          rName,             // 1. roomName (String)
                          rDesc,             // 2. description (String)
                          widget.configData, // 3. configData (Map<String, dynamic>?)
                          defaultRoomPath,   // 4. defaultRoomPath (String)
                        );

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 50,
                              height: 40,
                              color: Colors.black12,
                              child: imgPath.startsWith('assets/')
                                  ? Image.asset(imgPath, fit: BoxFit.cover)
                                  : Image.file(File(imgPath), fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            rDesc.isNotEmpty ? rDesc : 'Ảnh riêng phòng lẻ', 
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.photo_library, color: Color(0xFF0284C7), size: 20),
                            tooltip: 'Đổi ảnh riêng phòng này',
                            onPressed: () async {
                              debugPrint('🖼️ [TAB 2 PICKER] Bấm chọn ảnh riêng cho phòng lẻ: "$rName"');
                              final XFile? image = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                final prefs = await SharedPreferences.getInstance();
                                String storageKey = 'custom_room_layout_$rName';
                                await prefs.setString(storageKey, image.path);
                                debugPrint('💾 [SAVE PREFS TAB 2] Đã lưu ảnh lẻ "$storageKey" -> Path: ${image.path}');

                                imageCache.clear();
                                imageCache.clearLiveImages();

                                if (mounted) {
                                  setState(() {
                                    _overrideRoomLayouts[rName] = image.path;
                                    // Nếu phòng vừa đổi ảnh đang được active trên màn hình -> Cập nhật ảnh render luôn
                                    if (_activeRoomTitle == rName) {
                                      _currentRoomImageUrl = image.path;
                                    }
                                  });
                                }
                                setDialogState(() {});
                              } else {
                                debugPrint('ℹ️ [TAB 2 PICKER] Người dùng hủy chọn ảnh.');
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint('🚪 [DIALOG CLOSE] Đã đóng Dialog Quản lý ảnh phòng');
                    Navigator.pop(dialogContext);
                  },
                  child: Text(_isEn ? 'Close' : 'Đóng'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
  Future<void> _loadLocalImageOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  String fName = widget.floorName;
  String floorKey = _getStorageKey(fName);
  String? savedFloorImg = prefs.getString(floorKey);
  
  String activeFloorImagePath = (savedFloorImg != null && savedFloorImg.isNotEmpty)
      ? savedFloorImg
      : (widget.roomImageConfig ?? 'assets/images/default_floor.jpg');

  debugPrint('🏢 [ROOM SCREEN INIT] Ảnh Tầng mặc định/override: $activeFloorImagePath');

  Map<String, String> loadedRoomLayouts = {};
  
  // 🟢 1. Nạp ảnh cho các Loại Căn Động trước
  List<String> roomTypes = getDynamicRoomTypes(widget.configData);
  for (String typeKey in roomTypes) {
    String categoryStorageKey = _getCategoryStorageKey(typeKey);
    String? savedCategoryImg = prefs.getString(categoryStorageKey);
    if (savedCategoryImg != null && savedCategoryImg.isNotEmpty) {
      loadedRoomLayouts[typeKey] = savedCategoryImg;
      debugPrint('🏷️ [LOAD PREFS OK] Loại Căn "$typeKey" -> Path: $savedCategoryImg');
    }
  }

  // 🟢 2. Nạp ảnh cho từng Căn Hộ lẻ (nếu có override riêng)
  for (var r in widget.rooms) {
    String rName = r is List ? r[2].toString().trim() : (r['room_number'] ?? r['name'] ?? '').toString().trim();
    if (rName.isNotEmpty) {
      String roomKey = _getCategoryStorageKey(rName);
      String? savedRoomImg = prefs.getString(roomKey);
      if (savedRoomImg != null && savedRoomImg.isNotEmpty) {
        loadedRoomLayouts[rName] = savedRoomImg;
        debugPrint('📸 [LOAD PREFS OK] Căn lẻ "$rName" -> Path: $savedRoomImg');
      }
    }
  }

  if (mounted) {
    setState(() {
      _overrideFloorImagePath = activeFloorImagePath;
      _overrideRoomLayouts = loadedRoomLayouts;
      _currentRoomImageUrl = activeFloorImagePath;
    });
  }
}
  void _precacheRoomLayouts() async {
  if (!mounted) return;
  final Stopwatch stopwatch = Stopwatch()..start();
  debugPrint('🚀 [PRECACHE START] Bắt đầu nạp đệm danh sách ảnh local...');
  try {
    final Map<String, dynamic> roomLayoutsMap = _cachedRoomLayouts.isNotEmpty
        ? _cachedRoomLayouts
        : (widget.configData?['room_layouts'] as Map<String, dynamic>? ?? {});
    if (roomLayoutsMap.isEmpty) {
      debugPrint('⚠️ [PRECACHE CANCEL] Danh sách room_layouts bị RỖNG!');
      return;
    }
    final String projectId = widget.configData?['project_id'] ??
        await ConfigService.getActiveProjectId();
    final precacheTasks = roomLayoutsMap.entries.map((entry) async {
      final String rawKey = entry.key.toString();
      final String defaultValue = entry.value.toString();
      final String layoutKey = 'room_${rawKey.toLowerCase()}';
      if (defaultValue.isEmpty) return;
      final String imagePath = await ImageResolver.getActiveImagePath(
        projectId: projectId,
        imageKey: layoutKey,
        cloudUrl: defaultValue,
      );
      if (imagePath.startsWith('assets/')) {
        if (!mounted) return;
        await precacheImage(
          AssetImage(imagePath),
          context, // Truy cập State.context
        ).catchError((_) {});
      } else {
        final file = File(imagePath);
        final bool fileExists = await file.exists();
        if (!mounted || !fileExists) return;
        await precacheImage(
          FileImage(file),
          context, // Truy cập State.context
        ).catchError((_) {});
      }
    });
    await Future.wait(precacheTasks);
    stopwatch.stop();
    debugPrint(
      '✅ [PRECACHE FINISHED] Nạp xong toàn bộ ${roomLayoutsMap.length} ảnh vào RAM trong: ${stopwatch.elapsedMilliseconds} ms',
    );
  } catch (e) {
    debugPrint('⚠️ [PRECACHE ERROR] $e');
  }
}
  @override
  void didUpdateWidget(covariant RoomsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.configData != oldWidget.configData &&
        widget.configData != null &&
        widget.configData!.containsKey('room_layouts')) {
      setState(() {
        _cachedRoomLayouts = Map<String, dynamic>.from(
          widget.configData!['room_layouts'],
        );
      });
      debugPrint(
        '🔄 [UPDATED] Đã cập nhật lại _cachedRoomLayouts do configData thay đổi!',
      );
    }
  }
  Map<String, String> _getRoomInfoDetails(
    String roomName,
    Map<String, dynamic>? configData,
  ) {
    String cleanName = roomName.trim().toUpperCase();
    Map<String, dynamic> customInfos = configData?['custom_room_info'] ?? {};
    if (customInfos.containsKey(roomName)) {
      var info = customInfos[roomName];
      return {
        'Area': info['area'] ?? '68.5 m²',
        'Type': info['type'] ?? '2 Bedroom',
        'Balcony': info['balcony'] ?? 'South-East',
        'Status': info['status'] ?? 'Available',
      };
    }
    if (cleanName.contains('2BR') || cleanName.contains('2PN')) {
      return {
        'Area': '65 - 72 m²',
        'Type': '2 Bedrooms + 2 WC',
        'View': 'City & Swimming Pool View',
      };
    }
    if (cleanName.contains('3BR') || cleanName.contains('3PN')) {
      return {
        'Area': '88 - 105 m²',
        'Type': '3 Bedrooms + 2 WC',
        'View': 'River & Park View',
      };
    }
    if (cleanName.contains('SHOPHOUSE') || cleanName.contains('SHOUSE')) {
      return {
        'Area': '120 - 180 m²',
        'Type': 'Duplex Commercial Shophouse',
        'View': 'Main Street Frontage',
      };
    }
    return {
      'Area': 'Public Amenity',
      'Type': 'Shared Facility',
      'Access': '24/7 Residents Only',
    };
  }
 void _handleRoomTap(String roomName, int ledIdx, dynamic roomObj) {
  // 1. Đảo trạng thái LED
  bool isOn = widget.isAnyLedOn([ledIdx]);
  bool newState = !isOn;
  widget.ledStates[ledIdx] = newState;
  widget.onToggleLeds([ledIdx], newState);

  // 2. Gửi tín hiệu WebSocket sang sa bàn / Master
  if (WebSocketService().isConnected) {
    WebSocketService().sendSingleRoom(ledIdx, newState);
  }

  // 3. Xác định các đường dẫn ảnh Fallback chuẩn
  // - Ảnh tầng: Dùng khi không bấm phòng nào (hoặc khi tắt phòng - OFF)
  String defaultFloorPath = _overrideFloorImagePath ?? 'assets/images/default_floor.jpg';
  // - Ảnh phòng mặc định: Fallback khi bật phòng (ON) nhưng phòng/loại căn chưa được gán ảnh custom
  String defaultRoomPath = widget.roomImageConfig ?? 'assets/images/default_room.jpg';

  // 4. Bóc tách thông tin từ roomObj để gọi getRoomLayoutPath đúng 4 tham số (String, String, Map?, String)
  String description = '';
  if (roomObj is Map<String, dynamic>) {
    description = roomObj['description']?.toString() ?? '';
  } else if (roomObj is List && roomObj.length > 5) {
    // Trường hợp roomObj là List dạng flat_rooms [id, floor, name, code, led, description]
    description = roomObj[5]?.toString() ?? '';
  }

  // 5. Tính toán đường dẫn ảnh render
  // - Nếu ON: Gọi getRoomLayoutPath với đúng 4 tham số (RoomName, Description, ConfigData, DefaultRoomPath)
  // - Nếu OFF: Quay về ảnh mặt bằng tầng (DefaultFloorPath)
  String finalPath = newState 
      ? getRoomLayoutPath(roomName, description, widget.configData, defaultRoomPath) 
      : defaultFloorPath;

  // 6. Log debug hỗ trợ kiểm tra chi tiết luồng xử lý
  debugPrint('==================== [DEBUG TAP ROOM] ====================');
  debugPrint('👉 Căn hộ vừa bấm: "$roomName" | LED Index: #$ledIdx | Trạng thái: ${newState ? "ON" : "OFF"}');
  debugPrint('📝 Description bóc tách: "$description"');
  debugPrint('🖼️ Path ảnh render cuối: "$finalPath"');
  debugPrint('==========================================================');

  // 7. Cập nhật Giao diện
  if (mounted) {
    setState(() {
      _activeRoomTitle = newState ? roomName : null;
      _currentRoomImageUrl = finalPath;
    });
  }
}
  List<List<dynamic>> _chunkRooms(List<dynamic> list, int itemsPerRow) {
    List<List<dynamic>> chunks = [];
    for (int i = 0; i < list.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < list.length) ? i + itemsPerRow : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? configMap = widget.configData;
    final bool showRoomInfo = configMap?['settings']?['show_room_info'] ?? true;
    String defaultFloorPath =
        widget.roomImageConfig ?? 'assets/images/room.jpg';
    String activeFloorPath =
        (_overrideFloorImagePath != null && _overrideFloorImagePath!.isNotEmpty)
        ? _overrideFloorImagePath!
        : defaultFloorPath;
    final String currentImagePath =
        (_currentRoomImageUrl != null && _currentRoomImageUrl!.isNotEmpty)
        ? _currentRoomImageUrl!
        : activeFloorPath;
    Map<String, String>? activeRoomInfo = _activeRoomTitle != null
        ? _getRoomInfoDetails(_activeRoomTitle!, configMap)
        : null;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DynamicImage(
              imagePath: currentImagePath,
              fit: BoxFit.cover,
              fallbackAsset: 'assets/images/room.jpg',
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
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                bool isPhone = screenWidth < 600;
                return Column(
                  children: [
                    _buildTopBar(context, activeFloorPath),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 12.0 : 16.0,
                          vertical: isPhone ? 4.0 : 8.0,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              key: ValueKey(
                                'gesture_room_${_activeRoomTitle}_$currentImagePath',
                              ),
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (details) {},
                              onHorizontalDragUpdate: (details) {},
                              onHorizontalDragEnd: (details) {
                                double velocity = details.primaryVelocity ?? 0;
                                if (velocity > 150) {
                                  if (Navigator.canPop(context)) {
                                    _resetZoomAndExecute(() {
                                      Navigator.pop(context);
                                    });
                                  }
                                }
                              },
                              child: Container(
                                key: ValueKey(
                                  '${_activeRoomTitle}_$currentImagePath',
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7)
                                          .withValues(alpha: 0.22),
                                      blurRadius: 24,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      InteractiveImageViewer(
                                        key: ValueKey(
                                          'img_${_activeRoomTitle}_$currentImagePath',
                                        ),
                                        imagePath: currentImagePath,
                                        borderRadius: 20.0,
                                      ),
                                      if (_activeRoomTitle != null &&
                                          activeRoomInfo != null &&
                                          showRoomInfo)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 12,
                                                sigmaY: 12,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.55),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.sensor_door,
                                                          color: Color(
                                                            0xFF38BDF8,
                                                          ),
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          _activeRoomTitle!,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    ...activeRoomInfo.entries.map(
                                                      (e) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2.0,
                                                            ),
                                                        child: Text(
                                                          '• ${e.key.toUpperCase()}: ${e.value}',
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.88,
                                                                ),
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
                      child: _buildAdaptiveRoomPanel(context, isPhone),
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
  Widget _buildTopBar(BuildContext context, String defaultFloorPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF0369A1),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: IconButton(
              tooltip: _isEn ? 'Manage Room Images' : 'Quản lý ảnh các căn hộ',
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF0369A1),
                size: 22,
              ),
              onPressed: () => _showQuickEditRoomDialog(
                context,
              ), // 🟢 Gọi Dialog Menu 3 gạch
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCompactRoomButton(dynamic room, bool isPhone) {
    int ledIdx =
        int.tryParse('${room['led_index'] ?? room['hardwareIndex'] ?? 0}') ?? 0;
    bool isOn = widget.isAnyLedOn([ledIdx]);
    String roomName = room['room_number'] ?? room['name'] ?? 'Room';
    final bool isSelected =
        _activeRoomTitle?.toLowerCase() == roomName.toLowerCase();
    return InkWell(
      onTap: () => _handleRoomTap(roomName, ledIdx, room),
onDoubleTap: () => _handleRoomTap(roomName, ledIdx, room),
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
            color: isSelected
                ? const Color(
                    0xFF0284C7,
                  ) // Viền xanh dương Cyan nổi bật khi Active
                : (isOn ? Colors.amberAccent : const Color(0xFFF472B6)),
            width: isSelected
                ? 2.5
                : 1.2, // Tăng độ dầy viền lên 2.5px khi active
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
                isOn ? Icons.lightbulb : Icons.king_bed_outlined,
                size: isPhone ? 11 : 13,
                color: isOn ? Colors.white : const Color(0xFFDB2777),
              ),
            ),
            SizedBox(width: isPhone ? 3 : 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      roomName,
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
                      'LED #$ledIdx | ${isOn ? "ON" : "OFF"}',
                      style: TextStyle(
                        fontSize: isPhone ? 7.5 : 8.5,
                        fontWeight: isOn ? FontWeight.bold : FontWeight.w600,
                        color: isOn
                            ? Colors.yellow.shade100
                            : const Color(0xFF9D174D),
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
  Widget _buildAdaptiveRoomPanel(BuildContext context, bool isPhone) {
    int itemsPerRow = isPhone ? 4 : 5;
    List<List<dynamic>> roomRows = _chunkRooms(widget.rooms, itemsPerRow);
    double spacing = isPhone ? 4.0 : 12.0;
    dynamic activeRoomObj;
bool isRoomSelected = _activeRoomTitle != null && _activeRoomTitle!.isNotEmpty;
if (isRoomSelected) {
  try {
    activeRoomObj = widget.rooms.firstWhere(
      (r) =>
          (r['room_number'] ?? r['name'] ?? '').toString().toLowerCase() ==
          _activeRoomTitle!.toLowerCase(),
    );
  } catch (_) {
    activeRoomObj = null;
  }
}
String activeDisplayTitle = isRoomSelected
    ? (activeRoomObj != null 
        ? (activeRoomObj['room_number'] ?? activeRoomObj['name'] ?? _activeRoomTitle!).toString().toUpperCase()
        : _activeRoomTitle!.toUpperCase())
    : _currentFloorName.toUpperCase();
    List<int> allFloorRoomLeds = [];
    bool isAnyRoomOn = false;
    for (var r in widget.rooms) {
      int ledIdx =
          int.tryParse('${r['led_index'] ?? r['hardwareIndex'] ?? 0}') ?? 0;
      allFloorRoomLeds.add(ledIdx);
      if (widget.isAnyLedOn([ledIdx])) {
        isAnyRoomOn = true; // Chỉ cần 1 căn hộ BẬT -> Master On
      }
    }
    allFloorRoomLeds = allFloorRoomLeds.toSet().toList();
    bool isFloorMasterOn = isAnyRoomOn;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers, size: 18, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    'Mặt bằng: $activeDisplayTitle',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 8 : 16,
            vertical: isPhone ? 8 : 12,
          ),
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
                  Icon(
                    Icons.tune,
                    size: isPhone ? 13 : 15,
                    color: const Color(0xFF0369A1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEn
                        ? 'DIRECT ROOM CONTROL'
                        : 'ĐIỀU KHIỂN CĂN HỘ TRỰC TIẾP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isPhone ? 6 : 8),
              InkWell(
                onTap: () {
                  if (allFloorRoomLeds.isEmpty) return;
                  bool targetState = !isFloorMasterOn;
                  widget.onToggleLeds(allFloorRoomLeds, targetState);
                  setState(() {
                    if (!targetState) {
                      _activeRoomTitle = null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 14 : 22,
                    vertical: isPhone ? 5 : 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: isFloorMasterOn
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFF0F9FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFloorMasterOn
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF0284C7),
                      width: isFloorMasterOn ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFloorMasterOn
                            ? const Color(0xFFEC4899).withValues(alpha: 0.45)
                            : const Color(0xFF0284C7).withValues(alpha: 0.15),
                        blurRadius: isFloorMasterOn ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isFloorMasterOn
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF0284C7).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFloorMasterOn
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          size: isPhone ? 13 : 15,
                          color: isFloorMasterOn
                              ? Colors.amberAccent
                              : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isFloorMasterOn
                                ? (_isEn
                                      ? 'TURN OFF ALL ROOMS'
                                      : 'TẮT TỔNG TẦNG')
                                : (_isEn
                                      ? 'TURN ON ALL ROOMS'
                                      : 'BẬT TỔNG TẦNG'),
                            style: TextStyle(
                              fontSize: isPhone ? 10.5 : 12.0,
                              fontWeight: FontWeight.bold,
                              color: isFloorMasterOn
                                  ? Colors.white
                                  : const Color(0xFF0284C7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${allFloorRoomLeds.length} p | ${isFloorMasterOn ? (_isEn ? "ON" : "ĐANG BẬT") : (_isEn ? "OFF" : "ĐANG TẮT")}',
                            style: TextStyle(
                              fontSize: isPhone ? 8.0 : 9.0,
                              fontWeight: FontWeight.w600,
                              color: isFloorMasterOn
                                  ? Colors.yellow.shade200
                                  : const Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isPhone ? 8 : 10),
              Column(
                children: roomRows.map((rowRooms) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: isPhone ? 4 : 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rowRooms.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var room = entry.value;
                        Widget item = _buildCompactRoomButton(room, isPhone);
                        return isPhone
                            ? Flexible(
                                fit: FlexFit.tight,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: idx == rowRooms.length - 1
                                        ? 0
                                        : spacing,
                                  ),
                                  child: item,
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.only(
                                  right: idx == rowRooms.length - 1
                                      ? 0
                                      : spacing,
                                ),
                                child: SizedBox(width: 140.0, child: item),
                              );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isEn
                      ? '• 1-Tap: Toggle Light & View Layout'
                      : '• Chạm 1 lần: Bật/Tắt Đèn & Hiển thị Layout',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
