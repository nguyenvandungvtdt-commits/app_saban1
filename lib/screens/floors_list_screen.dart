import 'dart:ui';
import 'package:flutter/material.dart';
import 'rooms_list_screen.dart';
import '../widgets/info_dialog.dart';
import '../services/websocket_service.dart';
import '../widgets/dynamic_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Chứa ImagePicker, XFile, ImageSource
import 'package:shared_preferences/shared_preferences.dart'; //
import '../widgets/interactive_image_viewer.dart';
class FloorsListScreen extends StatefulWidget {
  final String towerName; // 👈 Thêm biến towerName
  final Map<String, dynamic>? configData;
  final String buildingName;
  final List<dynamic> floors;
  final Map<int, bool> ledStates;
  final Function(List<int> leds, bool state) onToggleLeds;
  final bool Function(List<int> leds) isAnyLedOn;
  final List<int> Function(List<dynamic> rooms, {int? filterRoomType})
  extractLeds;
  final int selectedFilterType;
  final String? buildingImageConfig;
  final String currentLang; // 🟢 1. KHAI BÁO THÊM TRƯỜNG NÀY
  final String? defaultBuildingImage; // 👈 Thêm biến defaultBuildingImage
  const FloorsListScreen({
    super.key,
    required this.buildingName,
    required this.towerName, // 👈 Thêm vào constructor
    required this.floors,
    required this.ledStates,
    required this.onToggleLeds,
    required this.isAnyLedOn,
    required this.extractLeds,
    required this.selectedFilterType,
    this.buildingImageConfig,
    this.configData, // 🟢 2. Thêm tham số named parameter configData vào đây
    this.currentLang = 'vi',
    this.defaultBuildingImage, // 👈 Thêm vào constructor
  });
  @override
  State<FloorsListScreen> createState() => _FloorsListScreenState();
}
class _FloorsListScreenState extends State<FloorsListScreen>
    with SingleTickerProviderStateMixin {
  String errorMsg = ''; // 🟢 Dùng biến này để chứa thông báo lỗi nội bộ Dialog
List<int> _parseRangeInput(String input) {
  List<int> targetFloors = [];
  String trimmed = input.trim();
  if (trimmed.isEmpty) return targetFloors;
  List<String> segments = trimmed.split(',');
  for (String segment in segments) {
    String part = segment.trim();
    if (part.isEmpty) continue;
    if (part.contains('-')) {
      List<String> bounds = part.split('-');
      if (bounds.length == 2) {
        int? start = int.tryParse(bounds[0].trim());
        int? end = int.tryParse(bounds[1].trim());
        if (start != null && end != null) {
          if (start <= end) {
            for (int i = start; i <= end; i++) {
              targetFloors.add(i);
            }
          } else {
            for (int i = start; i >= end; i--) {
              targetFloors.add(i);
            }
          }
        }
      }
    } 
    else {
      int? single = int.tryParse(part);
      if (single != null) {
        targetFloors.add(single);
      }
    }
  }
  return targetFloors.toSet().toList();
}
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  String? _overrideFloorImagePath;
  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
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
  }
  String _getFloorImagePath(String floorTitle) {
    if (_overrideFloorImages.containsKey(floorTitle) &&
        _overrideFloorImages[floorTitle] != null &&
        _overrideFloorImages[floorTitle]!.isNotEmpty) {
      return _overrideFloorImages[floorTitle]!;
    }
    return _resolveFloorImageFromConfig(floorTitle);
  }
  String? _activeFloorTitle; // Tầng đang chọn làm tiêu điểm ảnh
  final Map<String, String> _overrideFloorImages =
      {}; // Override ảnh local từ Quick Edit
  late String _projectName;
  late String _overviewImage;
  bool get _isEn => widget.currentLang == 'en';
  int? _extractFloorNumber(String floorTitle) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(floorTitle);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }
  String getSmartFloorImagePath(
    String floorName,
    String towerName,
    Map<String, dynamic>? configData,
    String defaultBuildingImg,
  ) {
    if (configData == null) return defaultBuildingImg;
    String cleanTower = towerName.trim().toUpperCase();
    RegExp regExp = RegExp(r'\d+');
    Match? match = regExp.firstMatch(floorName);
    if (match == null) return defaultBuildingImg;
    int floorNum = int.parse(match.group(0)!);
    Map<String, dynamic> towersConfig = configData['towers'] ?? {};
    Map<String, dynamic> templates = configData['floor_layout_templates'] ?? {};
    Map<String, dynamic> defaultTowerImgs =
        configData['default_tower_images'] ?? {};
    Map<String, dynamic>? towerData = towersConfig[cleanTower];
    if (towerData != null) {
      for (String key in towerData.keys) {
        bool isMatch = false;
        if (key.contains('-')) {
          List<String> parts = key.split('-');
          int start = int.parse(parts[0].trim());
          int end = int.parse(parts[1].trim());
          if (floorNum >= start && floorNum <= end) isMatch = true;
        } else {
          int? singleFloor = int.tryParse(key.trim());
          if (singleFloor != null && singleFloor == floorNum) isMatch = true;
        }
        if (isMatch) {
          String rawPath = towerData[key].toString();
          if (rawPath.startsWith('\$') &&
              templates.containsKey(rawPath.substring(1))) {
            return templates[rawPath.substring(1)]!;
          }
          if (rawPath.startsWith('\$') && rawPath.contains('.')) {
            List<String> refParts = rawPath.substring(1).split('.');
            String refTower = refParts[0];
            String refKey = refParts[1];
            if (towersConfig.containsKey(refTower) &&
                towersConfig[refTower].containsKey(refKey)) {
              String refPath = towersConfig[refTower][refKey].toString();
              if (refPath.startsWith('\$') &&
                  templates.containsKey(refPath.substring(1))) {
                return templates[refPath.substring(1)]!;
              }
              return refPath;
            }
          }
          return rawPath;
        }
      }
    }
    if (defaultTowerImgs.containsKey(cleanTower) &&
        defaultTowerImgs[cleanTower].toString().isNotEmpty) {
      return defaultTowerImgs[cleanTower];
    }
    return defaultBuildingImg;
  }
  @override
  @override
void initState() {
  super.initState();
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
  _projectName = widget.buildingName;
  _overviewImage = (widget.buildingImageConfig != null &&
          widget.buildingImageConfig!.isNotEmpty)
      ? widget.buildingImageConfig!
      : _getTowerDefaultAsset(widget.buildingName);
  _loadTowerConfig();
}
  List<List<dynamic>> _chunkFloors(List<dynamic> floorsList, int itemsPerRow) {
    List<List<dynamic>> chunks = [];
    for (int i = 0; i < floorsList.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < floorsList.length)
          ? i + itemsPerRow
          : floorsList.length;
      chunks.add(floorsList.sublist(i, end));
    }
    return chunks;
  }
  String _getTowerDefaultAsset(String name) {
  String clean = name.toLowerCase().replaceAll(' ', '_');
  if (clean.contains('thap_a') || clean.contains('tower_a') || clean.contains('a')) {
    return 'assets/images/tower/tower_a.jpg';
  }
  if (clean.contains('thap_b') || clean.contains('tower_b') || clean.contains('b')) {
    return 'assets/images/tower/tower_b.jpg';
  }
  if (clean.contains('thap_c') || clean.contains('tower_c') || clean.contains('c')) {
    return 'assets/images/tower/tower_c.jpg';
  }
  if (clean.contains('thap_d') || clean.contains('tower_d') || clean.contains('d')) {
    return 'assets/images/tower/tower_d.jpg';
  }
  if (clean.contains('thap_e') || clean.contains('tower_e') || clean.contains('e')) {
    return 'assets/images/tower/tower_e.jpg';
  }
  return widget.defaultBuildingImage ?? 'assets/images/building.jpg';
}
String _resolveFloorImageFromConfig(String floorTitle) {
  for (var f in widget.floors) {
    String currentFloorName = f['name'] ?? f['title'] ?? '';
    if (currentFloorName.toUpperCase() == floorTitle.toUpperCase()) {
      if (f['image'] != null && f['image'].toString().isNotEmpty) {
        return f['image'].toString();
      }
    }
  }
  return 'assets/images/default_floor.jpg';
}
  String getRoomLayoutPath(String roomName, Map<String, dynamic>? configData) {
    String cleanName = roomName.trim().toUpperCase();
    if (configData != null && configData.containsKey('custom_room_images')) {
      Map<String, dynamic> customImages = configData['custom_room_images'];
      if (customImages.containsKey(roomName) &&
          customImages[roomName].toString().isNotEmpty) {
        return customImages[roomName];
      }
    }
    Map<String, dynamic> layoutsInJson = configData?['room_layouts'] ?? {};
    if (cleanName.contains('2BR') || cleanName.contains('2PN')) {
      return layoutsInJson['2PN'] ?? 'assets/images/layout_2pn.jpg';
    }
    if (cleanName.contains('3BR') || cleanName.contains('3PN')) {
      return layoutsInJson['3PN'] ?? 'assets/images/layout_3pn.jpg';
    }
    if (cleanName.contains('4BR') || cleanName.contains('4PN')) {
      return layoutsInJson['4PN'] ?? 'assets/images/layout_4pn.jpg';
    }
    if (cleanName.contains('SHOPHOUSE') || cleanName.contains('SHOUSE')) {
      return layoutsInJson['SHOPHOUSE'] ?? 'assets/images/layout_shophouse.jpg';
    }
    if (cleanName.contains('PENTHOUSE')) {
      return layoutsInJson['PENTHOUSE'] ?? 'assets/images/layout_penthouse.jpg';
    }
    if (cleanName.contains('DUPLEX')) {
      return layoutsInJson['DUPLEX'] ?? 'assets/images/layout_duplex.jpg';
    }
    if (cleanName.contains('SẢNH') || cleanName.contains('SANH')) {
      return layoutsInJson['SANH'] ?? 'assets/images/facility_sanh.jpg';
    }
    if (cleanName.contains('GYM')) {
      return layoutsInJson['GYM'] ?? 'assets/images/facility_gym.jpg';
    }
    return 'assets/images/room.jpg';
  }
  @override
Widget build(BuildContext context) {
  String towerOrBuildingName = (widget.towerName.isNotEmpty) ? widget.towerName : widget.buildingName;
  final String specificFallback = _getTowerDefaultAsset(towerOrBuildingName);
  String defaultImagePath = _overviewImage.isNotEmpty
      ? _overviewImage
      : specificFallback;
  final String currentImagePath =
      (_overrideFloorImagePath != null && _overrideFloorImagePath!.isNotEmpty)
      ? _overrideFloorImagePath!
      : (_activeFloorTitle != null
            ? _getFloorImagePath(_activeFloorTitle!)
            : defaultImagePath);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
  child: DynamicImage(
    key: ValueKey('bg_floor_$currentImagePath'), // 🟢 Đổi sang currentImagePath để nền và ảnh chính đồng bộ
    imagePath: currentImagePath,
    fit: BoxFit.cover,
    fallbackAsset: specificFallback,
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
                    _buildTopBar(context),
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
                                'gesture_floor_${_activeFloorTitle}_$currentImagePath',
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
                                  '${_activeFloorTitle}_$currentImagePath',
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
                                  child: InteractiveImageViewer(
                                    key: ValueKey(
                                      'img_${_activeFloorTitle}_${currentImagePath}_$_overrideFloorImagePath',
                                    ),
                                    imagePath: currentImagePath,
                                    borderRadius: 20.0,
                                    gaplessPlayback: false, // Đặt false khi thay ảnh từ thư viện thiết bị để không bị giữ hình ảnh tầng cũ
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isPhone ? 10.0 : 16.0,
                        vertical: 2.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.layers_rounded,
                                color: Color(0xFF0284C7),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _activeFloorTitle != null
                                    ? 'Mặt bằng: $_activeFloorTitle'
                                    : 'Mặt bằng: Tổng Thể $_projectName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
                      child: _buildAdaptiveControlPanel(
                        context,
                        screenWidth,
                        isPhone,
                      ),
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF0369A1),
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                tooltip: _isEn
                    ? 'Edit Tower Name & Image'
                    : 'Chỉnh sửa tên & Ảnh tháp',
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF0369A1),
                  size: 22,
                ),
                onPressed: () {
                  _showQuickEditDialog(context);
                },
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.5),
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
                      _projectName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0369A1),
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
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  InfoDialog.show(
                    context,
                    title: _isEn
                        ? 'Tower Info: $_projectName'
                        : 'Thông Tin $_projectName',
                    details: {
                      _isEn ? 'Scale' : 'Quy mô':
                          '${widget.floors.length} ${_isEn ? "Floors" : "Tầng nổi"}',
                      _isEn ? 'Total Units' : 'Tổng số căn': _isEn
                          ? 'Luxury Apartments'
                          : 'Căn hộ cao cấp',
                      _isEn ? 'Status' : 'Trạng thái': _isEn
                          ? 'On Sale'
                          : 'Đang mở bán',
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
  Future<void> _loadTowerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String rawTowerName = widget.towerName.isNotEmpty ? widget.towerName : widget.buildingName;
    String cleanTowerKey = rawTowerName
        .toLowerCase()
        .replaceAll('tháp', 'thap')
        .replaceAll('tòa', 'toa')
        .replaceAll('tower', 'thap')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .toUpperCase(); // Trả về chuẩn: THAP_A, THAP_B, THAP_D...
    String storageKey = 'saved_tower_image_$cleanTowerKey';
    final savedImg = prefs.getString(storageKey) ?? 
                     prefs.getString('saved_tower_image_${rawTowerName.replaceAll(' ', '_').toUpperCase()}');
    final savedName = prefs.getString('saved_tower_name_$cleanTowerKey');
    Map<String, String> loadedFloorImages = {};
    for (var f in widget.floors) {
      String floorTitle = f['name'] ?? f['title'] ?? '';
      if (floorTitle.isNotEmpty) {
        String key = 'saved_floor_image_${widget.buildingName}_$floorTitle';
        String? savedFloorPath = prefs.getString(key);
        if (savedFloorPath != null && savedFloorPath.isNotEmpty) {
          if (savedFloorPath.startsWith('assets/') || File(savedFloorPath).existsSync()) {
            loadedFloorImages[floorTitle] = savedFloorPath;
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        if (savedName != null && savedName.isNotEmpty) {
          _projectName = savedName;
        }
        if (widget.buildingImageConfig != null &&
            widget.buildingImageConfig!.isNotEmpty &&
            (widget.buildingImageConfig!.startsWith('assets/') || File(widget.buildingImageConfig!).existsSync())) {
          _overviewImage = widget.buildingImageConfig!;
        } else if (savedImg != null &&
            savedImg.isNotEmpty &&
            (savedImg.startsWith('assets/') || File(savedImg).existsSync())) {
          _overviewImage = savedImg;
        } else {
          _overviewImage = _getTowerDefaultAsset(rawTowerName);
        }
        _overrideFloorImages.addAll(loadedFloorImages);
      });
    }
  }
  void _handleFloorTap(String floorTitle, List<int> fLeds, bool isOn) async {
    bool newState = !isOn;
    widget.onToggleLeds(fLeds, newState);
    WebSocketService().sendGroupRooms(fLeds, newState);
    String targetFloorTitle = newState ? floorTitle : (_activeFloorTitle ?? '');
    String newImagePath = '';
    if (targetFloorTitle.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      String key = 'saved_floor_image_${widget.buildingName}_$targetFloorTitle';
      String? savedFloorPath = prefs.getString(key);
      if (savedFloorPath != null &&
          savedFloorPath.isNotEmpty &&
          (savedFloorPath.startsWith('assets/') ||
              File(savedFloorPath).existsSync())) {
        newImagePath = savedFloorPath;
      } else {
        newImagePath = _getFloorImagePath(targetFloorTitle);
      }
    }
    if (mounted) {
      setState(() {
        _activeFloorTitle = targetFloorTitle.isEmpty ? null : targetFloorTitle;
        if (newImagePath.isNotEmpty) {
          _overrideFloorImagePath = newImagePath;
        } else {
          _overrideFloorImagePath = null; // Trả về ảnh Sa bàn Tháp tươi (_overviewImage)
        }
      });
    }
  }
  void _showQuickEditDialog(BuildContext context) {
    final TextEditingController rangeController = TextEditingController();
    String rangePreviewImage = '';
    String errorMsg = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.collections_bookmark_rounded,
                          color: Color(0xFF0369A1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEn
                              ? 'Manage Floor Images'
                              : 'Quản Lý Ảnh Các Tầng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      labelColor: const Color(0xFF0284C7),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF0284C7),
                      tabs: [
                        Tab(
                          icon: const Icon(
                            Icons.dynamic_feed_rounded,
                            size: 20,
                          ),
                          text: _isEn ? 'By Range' : 'Theo Dải Tầng',
                        ),
                        Tab(
                          icon: const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 20,
                          ),
                          text: _isEn ? 'All Floors' : 'Tất Cả Tầng',
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 390,
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              _isEn
                                  ? 'Apply 1 image for multiple floors:'
                                  : 'Áp dụng 1 ảnh cho nhiều tầng đồng dạng:',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: rangeController,
                              decoration: InputDecoration(
                                labelText: _isEn
                                    ? 'Floor Range (e.g. 3-9 or 10-18 or 1-5, 10)'
                                    : 'Dải tầng (Ví dụ: 3-9 hoặc 10-18 hoặc 1-5, 10)',
                                prefixIcon: const Icon(Icons.numbers_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: '3-9',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: rangePreviewImage.isNotEmpty
                                  ? (rangePreviewImage.startsWith('assets/')
                                        ? Image.asset(
                                            rangePreviewImage,
                                            key: ValueKey(
                                              'preview_$rangePreviewImage',
                                            ),
                                            fit: BoxFit.contain,
                                          )
                                        : Image.file(
                                            File(rangePreviewImage),
                                            key: ValueKey(
                                              'preview_$rangePreviewImage',
                                            ),
                                            fit: BoxFit.contain,
                                          ))
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 36,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Chưa chọn ảnh cho dải tầng',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      rangePreviewImage = image.path;
                                      errorMsg = '';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: Text(
                                  _isEn
                                      ? 'Choose Shared Image'
                                      : 'Chọn Ảnh Dùng Chung',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (errorMsg.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  errorMsg,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.done_all_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _isEn ? 'Apply Range' : 'Áp Dụng Dải',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () async {
                                      String input = rangeController.text
                                          .trim();
                                      List<int> targetFloors = _parseRangeInput(
                                        input,
                                      );
                                      if (targetFloors.isEmpty) {
                                        setDialogState(() {
                                          errorMsg = '⚠️ Vui lòng nhập dải tầng hợp lệ (Ví dụ: 3-9)!';
                                        });
                                        return;
                                      }
                                      if (rangePreviewImage.isEmpty) {
                                        setDialogState(() {
                                          errorMsg = '⚠️ Vui lòng nhấn "Chọn Ảnh Dùng Chung" trước!';
                                        });
                                        return;
                                      }
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      Map<String, String> updatedMap = {};
                                      for (var f in widget.floors) {
                                        String fTitle =
                                            f['name'] ?? f['title'] ?? '';
                                        int? num = _extractFloorNumber(fTitle);
                                        bool isMatch =
                                            num != null &&
                                            targetFloors.contains(num);
                                        if (isMatch) {
                                          String storageKey = _getStorageKey(
                                            fTitle,
                                          ); // 🟢 Key động
                                          await prefs.setString(
                                            storageKey,
                                            rangePreviewImage,
                                          );
                                          updatedMap[fTitle] =
                                              rangePreviewImage;
                                        }
                                      }
                                      imageCache.clear();
                                      imageCache.clearLiveImages();
                                      if (mounted) {
                                        setState(() {
                                          _overrideFloorImages.addAll(
                                            updatedMap,
                                          );
                                          if (_activeFloorTitle != null &&
                                              updatedMap.containsKey(
                                                _activeFloorTitle,
                                              )) {
                                            _overrideFloorImagePath =
                                                rangePreviewImage;
                                          }
                                        });
                                      }
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        itemCount: widget.floors.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final floor = widget.floors[index];
                          String fName =
                              floor['name'] ??
                              floor['title'] ??
                              'Tầng ${index + 1}';
                          String imgPath = _getFloorImagePath(fName);
                          bool isCustomized = _overrideFloorImages.containsKey(
                            fName,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 50,
                                    height: 40,
                                    color: Colors.black12,
                                    child: imgPath.startsWith('assets/')
                                        ? Image.asset(
                                            imgPath,
                                            key: ValueKey(
                                              'tab2_${fName}_${isCustomized}_$imgPath',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(imgPath),
                                            key: ValueKey(
                                              'tab2_${fName}_${isCustomized}_$imgPath',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    fName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_library,
                                    color: Color(0xFF0284C7),
                                    size: 20,
                                  ),
                                  tooltip: 'Đổi ảnh tầng này',
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (image != null) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      String storageKey = _getStorageKey(fName);
                                      await prefs.setString(
                                        storageKey,
                                        image.path,
                                      );
                                      imageCache.clear();
                                      imageCache.clearLiveImages();
                                      if (mounted) {
                                        setState(() {
                                          _overrideFloorImages[fName] =
                                              image.path;
                                          if (_activeFloorTitle == fName) {
                                            _overrideFloorImagePath =
                                                image.path;
                                          }
                                        });
                                      }
                                      setDialogState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
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
String _getStorageKey(String rawFloorTitle) {
  String bName = widget.buildingName;
  String cleanFloorTitle = rawFloorTitle;
  if (rawFloorTitle.contains(' - ')) {
    List<String> parts = rawFloorTitle.split(' - ');
    if (bName.isEmpty) {
      bName = parts[0].trim(); // Tách lấy "THÁP A"
    }
    cleanFloorTitle = parts[1].trim(); // Tách lấy "TẦNG 02"
  }
  return 'saved_floor_image_${bName}_$cleanFloorTitle';
}
  Widget _buildAdaptiveControlPanel(
    BuildContext context,
    double screenWidth,
    bool isPhone,
  ) {
    int targetRows = 3;
    int itemsPerRow = (widget.floors.length / targetRows).ceil();
    if (itemsPerRow < 1) itemsPerRow = 1;
    List<List<dynamic>> floorRows = _chunkFloors(widget.floors, itemsPerRow);
    double horizontalSpacing = isPhone ? 4.0 : 6.0;
    double verticalSpacing = isPhone ? 4.0 : 6.0;
    final String controlLevel =
        widget.configData?['project_info']?['control_level'] ?? 'FLOOR';
    List<int> allTowerLeds = [];
    bool isAnyFloorOn = false;
    for (var f in widget.floors) {
      List<int> fLeds = widget.extractLeds(
        f['rooms'],
        filterRoomType: widget.selectedFilterType,
      );
      allTowerLeds.addAll(fLeds);
      if (widget.isAnyLedOn(fLeds)) {
        isAnyFloorOn = true;
      }
    }
    allTowerLeds = allTowerLeds.toSet().toList();
    bool isTowerMasterOn = isAnyFloorOn;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 6 : 12,
        vertical: isPhone ? 6 : 8,
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
          SizedBox(height: isPhone ? 6 : 8),
          InkWell(
onTap: () {
  if (allTowerLeds.isEmpty) return;
  bool targetState = !isTowerMasterOn;
  widget.onToggleLeds(allTowerLeds, targetState);
  setState(() {
    if (!targetState) {
      _activeFloorTitle = null;
      _overrideFloorImagePath = null; // 🟢 Reset override để hiển thị đúng _overviewImage
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
                gradient: isTowerMasterOn
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
                  color: isTowerMasterOn
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF0284C7),
                  width: isTowerMasterOn ? 1.8 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isTowerMasterOn
                        ? const Color(0xFFEC4899).withValues(alpha: 0.45)
                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                    blurRadius: isTowerMasterOn ? 12 : 6,
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
                      color: isTowerMasterOn
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFF0284C7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTowerMasterOn
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      size: isPhone ? 13 : 15,
                      color: isTowerMasterOn
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
                        isTowerMasterOn ? 'TẮT TỔNG THÁP' : 'BẬT TỔNG THÁP',
                        style: TextStyle(
                          fontSize: isPhone ? 10.5 : 12.0,
                          fontWeight: FontWeight.bold,
                          color: isTowerMasterOn
                              ? Colors.white
                              : const Color(0xFF0284C7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${allTowerLeds.length} p | ${isTowerMasterOn ? "ĐANG BẬT" : "ĐANG TẮT"}',
                        style: TextStyle(
                          fontSize: isPhone ? 8.0 : 9.0,
                          fontWeight: FontWeight.w600,
                          color: isTowerMasterOn
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
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalSpacing / 2,
                        ),
                        child: _buildCompactButton(f, isPhone),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              (controlLevel == 'ROOM')
                  ? '• Chạm 1 lần: Bật/Tắt Tầng   |   • Nhấn đúp 2 lần: Danh sách căn hộ'
                  : '• Chạm 1 lần: Bật/Tắt Tầng sa bàn',
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
    final String floorTitle = f['name'] ?? f['title'] ?? 'TẦNG';
    // final String controlLevel =
    //     widget.configData?['project_info']?['control_level'] ?? 'FLOOR';
    String getControlLevel() {
  if (widget.configData == null) return 'FLOOR';
  
  // 1. Nếu configData chính là object của dự án đó
  if (widget.configData!.containsKey('project_info')) {
    return widget.configData!['project_info']?['control_level']?.toString() ?? 'FLOOR';
  }
  
  // 2. Nếu control_level nằm ngay ở root configData
  if (widget.configData!.containsKey('control_level')) {
    return widget.configData!['control_level']?.toString() ?? 'FLOOR';
  }
  
  return 'FLOOR';
}

final String controlLevel = getControlLevel();
    final bool isRoomLevel = (controlLevel == 'ROOM');
    final List<int> floorLeds = widget.extractLeds(
      f['rooms'],
      filterRoomType: widget.selectedFilterType,
    );
    final bool canNavigateToRooms = isRoomLevel && (floorLeds.length > 1);
    final bool isOn = widget.isAnyLedOn(floorLeds);
    final bool isSelected = _activeFloorTitle == floorTitle;
    double buttonWidth = isPhone ? 90.0 : 135.0;
    return InkWell(
      onTap: () {
        _handleFloorTap(floorTitle, floorLeds, isOn);
      },
      onDoubleTap: canNavigateToRooms
    ? () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
  builder: (context) => RoomsListScreen(
    buildingName: widget.buildingName, // 🟢 1. Truyền tên tòa nhà (Ví dụ: "THÁP A")
    floorName: floorTitle,            // 🟢 2. Truyền tên tầng thuần túy (Ví dụ: "TẦNG 02")
    roomImageConfig: f['image'],       // 🟢 3. BỔ SUNG: Truyền đường dẫn ảnh tầng mặc định từ config/JSON
    rooms: f['rooms'] ?? [],
    ledStates: widget.ledStates,
    onToggleLeds: widget.onToggleLeds,
    isAnyLedOn: widget.isAnyLedOn,
    configData: widget.configData,
    currentLang: widget.currentLang,
  ),
),
        );
        if (mounted) {
          setState(() {});
        }
      }
    : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: buttonWidth,
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
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isOn ? Colors.amberAccent : const Color(0xFFF472B6)),
            width: isSelected ? 2.0 : 1.2,
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
                      floorTitle,
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
                      '${floorLeds.length} p | ${isOn ? "BẬT" : "TẮT"}',
                      style: TextStyle(
                        fontSize: isPhone ? 7.0 : 8.5,
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
}
