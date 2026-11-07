import 'dart:ui';

import 'package:flutter/material.dart';

import 'floors_list_screen.dart';
import '../widgets/dynamic_image.dart';

import 'package:shared_preferences/shared_preferences.dart'; //
import 'package:flutter/foundation.dart';

import 'dart:io';

import '../widgets/interactive_image_viewer.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BuildingsListScreen extends StatefulWidget {
  final String? projectId; // 🟢 Bổ sung trường này
  final Map<String, dynamic>? configData;
  final List<Map<String, dynamic>> buildings;
  final Map<int, bool> ledStates;
  final Function(List<int> leds, bool state) onToggleLeds;
  final bool Function(List<int> leds) isAnyLedOn;
  final List<int> Function(List<dynamic> rooms, {int? filterRoomType})
  extractLeds;
  final int selectedFilterType;
  final String currentLang; // 🟢 1. KHAI BÁO THÊM TRƯỜNG NÀY
  const BuildingsListScreen({
    super.key,
    required this.buildings,
    required this.ledStates,
    required this.onToggleLeds,
    required this.isAnyLedOn,
    required this.extractLeds,
    required this.selectedFilterType,
    this.projectId, // 🟢 Bổ sung constructor parameter
    this.configData, // 🟢 2. Thêm tham số vào constructor
    this.currentLang = 'vi',
  });
  @override
  State<BuildingsListScreen> createState() => _BuildingsListScreenState();
}

class _BuildingsListScreenState extends State<BuildingsListScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
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

  // final Map<String, String> _customTowerImages = {};
  String _projectName = 'DANH SÁCH TÒA NHÀ';
  String _overviewImage = 'assets/images/building.jpg';
  String _selectedTowerImage = '';
  String _selectedTowerKey =
      ''; // Dùng để highlight nút tháp đang chọn (nếu cần)
  bool get _isEn => widget.currentLang == 'en';
  List<int> _getBuildingLeds(Map<String, dynamic> building) {
    List<int> leds = [];
    for (var f in building['floors']) {
      leds.addAll(
        widget.extractLeds(
          f['rooms'],
          filterRoomType: widget.selectedFilterType,
        ),
      );
    }
    return leds;
  }

  String _cleanTowerKey(String rawName) {
    return rawName
        .toLowerCase()
        .replaceAll('tháp', 'thap')
        .replaceAll('tòa', 'toa')
        .replaceAll('tower', 'thap')
        .replaceAll(' ', '_')
        .replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '',
        ) // Xóa dấu tiếng Việt và ký tự đặc biệt
        .toUpperCase();
  }

  String _getStorageKey(String rawName) {
    return 'saved_tower_image_${_cleanTowerKey(rawName)}';
  }

  List<int> _parseBuildingRangeInput(String input) {
    List<int> targetBuildings = [];
    String trimmed = input.trim();
    if (trimmed.isEmpty) return targetBuildings;
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
                targetBuildings.add(i);
              }
            } else {
              for (int i = start; i >= end; i--) {
                targetBuildings.add(i);
              }
            }
          }
        }
      } else {
        int? single = int.tryParse(part);
        if (single != null) {
          targetBuildings.add(single);
        }
      }
    }
    return targetBuildings.toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250), // Thời gian thu nhỏ ảnh
        )..addListener(() {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
        });
    _loadBuildingConfig();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/default_tower.jpg'), context);
  }

  void _showBuildingEditDialog(Map<String, dynamic> buildingData) {
    final String rawName = buildingData['name'] ?? buildingData['title'] ?? '';
    final String buildingKey = rawName.replaceAll(' ', '_').toUpperCase();
    String cleanSlug = rawName
        .toLowerCase()
        .replaceAll('tháp', '')
        .replaceAll('tower_', '')
        .replaceAll('_', '')
        .trim();
    // String targetTowerKey = cleanSlug.isNotEmpty
    //     ? 'tower_$cleanSlug'
    //     : buildingKey.toLowerCase();
    final TextEditingController nameController = TextEditingController(
      text: _overrideBuildingNames[buildingKey] ?? rawName,
    );
    String previewImagePath = _getBuildingImagePath(rawName);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_note, color: Color(0xFF0369A1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEn ? 'Edit Tower: $rawName' : 'Chỉnh Sửa: $rawName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: previewImagePath.isNotEmpty
                          ? (previewImagePath.startsWith('http')
                                ? Image.network(
                                    previewImagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  )
                                : (previewImagePath.startsWith('assets/')
                                      ? Image.asset(
                                          previewImagePath,
                                          fit: BoxFit.contain,
                                        )
                                      : Image.file(
                                          File(previewImagePath),
                                          fit: BoxFit.contain,
                                        )))
                          : const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Tower Name' : 'Tên Tháp / Tòa Nhà',
                        prefixIcon: const Icon(Icons.apartment_rounded),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (image == null) {
                              return;
                            }
                            String rawPath = kIsWeb
                                ? Uri.decodeFull(image.path)
                                : image.path;
                            String permPath = await _makeImagePermanent(
                              rawPath,
                              'tower_$cleanSlug',
                            );
                            setDialogState(() {
                              previewImagePath = permPath;
                            });
                          } catch (e) {
                            //
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: Text(
                          _isEn
                              ? 'Choose Image from Gallery'
                              : 'Chọn ảnh từ Thư viện',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_isEn ? 'Cancel' : 'Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    String newName = nameController.text.trim();
                    String cleanKey = _cleanTowerKey(rawName);
                    String cleanStorageKey = _getStorageKey(rawName);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      if (newName.isNotEmpty) {
                        await prefs.setString(
                          'saved_tower_name_$cleanKey',
                          newName,
                        );
                      }
                      if (previewImagePath.isNotEmpty) {
                        await prefs.setString(
                          cleanStorageKey,
                          previewImagePath,
                        );
                      }
                      if (mounted) {
                        setState(() {
                          if (newName.isNotEmpty) {
                            _overrideBuildingNames[cleanKey] = newName;
                          }
                          if (previewImagePath.isNotEmpty) {
                            _overrideBuildingImages[cleanKey] =
                                previewImagePath; // 🟢 Gán đúng CleanKey
                            _selectedTowerKey = cleanKey;
                            _selectedTowerImage = previewImagePath;
                          }
                        });
                      }
                    } catch (e) {
//
                    } finally {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(_isEn ? 'Save' : 'Lưu Thay Đổi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final Map<String, String> _overrideBuildingImages = {};
  final Map<String, String> _overrideBuildingNames = {};
  String _getBuildingDisplayName(String rawName) {
    String buildingKey = rawName.replaceAll(' ', '_').toUpperCase();
    return _overrideBuildingNames[buildingKey] ?? rawName;
  }

  String _getBuildingImagePath(String buildingName) {
    if (buildingName.isEmpty) {
      return 'assets/images/default_tower.jpg'; // 🟢 Ảnh chung duy nhất
    }
    String cleanKey = _cleanTowerKey(buildingName);
    if (_overrideBuildingImages.containsKey(cleanKey) &&
        _overrideBuildingImages[cleanKey] != null &&
        _overrideBuildingImages[cleanKey]!.isNotEmpty) {
      String foundPath = _overrideBuildingImages[cleanKey]!;
      bool isAsset = foundPath.startsWith('assets/');
      bool isHttp = foundPath.startsWith('http');
      bool isFileExist = (!isAsset && !isHttp) && File(foundPath).existsSync();
      if (isAsset || isHttp || isFileExist) {
        return foundPath;
      }
    }
    return 'assets/images/default_tower.jpg'; // 👈 (Thay bằng path ảnh chung của bạn, ví dụ: assets/images/building.jpg)
  }

  Future<String> _resolveTowerImage(String rawTowerName) async {
    final prefs = await SharedPreferences.getInstance();
    String storageKey = _getStorageKey(rawTowerName);
    String? savedPath = prefs.getString(storageKey);
    if (savedPath != null && savedPath.isNotEmpty) {
      bool isAsset = savedPath.startsWith('assets/');
      bool isFileExist = !isAsset && File(savedPath).existsSync();
      if (isAsset || isFileExist) {
        return savedPath; // Người dùng ĐÃ SỬA -> Trả về ảnh custom
      }
    }
    return 'assets/images/default_tower.jpg';
  }

  Future<void> _loadBuildingConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('saved_building_project_name');
    final savedImg = prefs.getString('saved_building_overview_image');
    String verifiedOverviewImage = 'assets/images/default_tower.jpg';
    if (savedImg != null && savedImg.isNotEmpty) {
      if (savedImg.startsWith('assets/')) {
        verifiedOverviewImage = savedImg;
      } else if (File(savedImg).existsSync()) {
        verifiedOverviewImage = savedImg;
      }
    }
    Map<String, String> loadedTowerImages = {};
    for (var b in widget.buildings) {
      String bName = b['name'] ?? b['title'] ?? '';
      if (bName.isNotEmpty) {
        String cleanKey = _cleanTowerKey(bName);
        String storageKey = _getStorageKey(bName);
        String? savedTowerPath = prefs.getString(storageKey);
        if (savedTowerPath != null && savedTowerPath.isNotEmpty) {
          if (savedTowerPath.startsWith('assets/') ||
              File(savedTowerPath).existsSync()) {
            loadedTowerImages[cleanKey] = savedTowerPath;
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _projectName = (savedName != null && savedName.isNotEmpty)
            ? savedName
            : 'DANH SÁCH TÒA NHÀ';
        _overviewImage = verifiedOverviewImage;
        _overrideBuildingImages.clear();
        _overrideBuildingImages.addAll(loadedTowerImages);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageToDisplay = _overviewImage;
    if (_selectedTowerKey.isNotEmpty && _selectedTowerImage.isNotEmpty) {
      imageToDisplay = _selectedTowerImage;
    }
    final UniqueKey imageKey = UniqueKey();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DynamicImage(
              key: ValueKey('bg_${imageToDisplay}_$imageKey'),
              imagePath: imageToDisplay,
              fit: BoxFit.cover,
              fallbackAsset:
                  'assets/images/building.jpg', // 👈 Đã sửa thành building.jpg
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
                    _buildTopBar(context, isPhone),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 10.0 : 16.0,
                          vertical: isPhone ? 4.0 : 6.0,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              key: ValueKey('gesture_building_$imageToDisplay'),
                              behavior: HitTestBehavior.opaque,
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
                                  'building_container_$imageToDisplay',
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
                                      'img_building_${imageToDisplay}_$imageKey',
                                    ),
                                    imagePath: imageToDisplay.isNotEmpty
                                        ? imageToDisplay
                                        : 'assets/images/building.jpg',
                                    borderRadius: 20.0,
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
                        vertical: 4.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment,
                                size: 18,
                                color: Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedTowerKey.isNotEmpty
                                    ? 'Mặt bằng: ${_selectedTowerKey.replaceAll('tower_', 'THÁP ').toUpperCase()}'
                                    : 'Mặt bằng tổng: ${_projectName.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

  void _showOverviewImageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String previewImage = _overviewImage;
        // final String defaultProjectName = _projectName.isNotEmpty
        //     ? _projectName
        //     : 'SA BÀN ĐỒNG VĂN CỐNG';
        final TextEditingController nameController = TextEditingController(
          text: _projectName,
        );
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(
                    _isEn ? 'Manage Building Overview' : 'Quản Lý Sa Bàn Tổng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEn ? 'Building Name:' : 'Tên Dự Án / Sa Bàn:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên dự án...',
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF0284C7),
                        ),
                        // suffixIcon: IconButton(
                        //   icon: const Icon(
                        //     Icons.refresh_rounded,
                        //     color: Colors.orange,
                        //   ),
                        //   tooltip: 'Khôi phục tên mặc định',
                        //   onPressed: () {
                        //     setDialogState(() {
                        //       nameController.text = defaultProjectName;
                        //     });
                        //   },
                        // ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEn ? 'Overview Image:' : 'Hình Ảnh Sa Bàn:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DynamicImage(
                          imagePath: previewImage,
                          fit: BoxFit.cover,
                          fallbackAsset: 'assets/images/building.jpg',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _isEn ? 'Pick Image' : 'Chọn Ảnh Mới',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null && image.path.isNotEmpty) {
                                setDialogState(() {
                                  previewImage = image.path;
                                });
                              }
                            },
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Expanded(
                        //   child: OutlinedButton.icon(
                        //     style: OutlinedButton.styleFrom(
                        //       foregroundColor: Colors.orange.shade800,
                        //       side: BorderSide(color: Colors.orange.shade400),
                        //     ),
                        //     icon: const Icon(Icons.restore_rounded, size: 16),
                        //     label: Text(
                        //       _isEn ? 'Restore Image' : 'Khôi Phục Ảnh',
                        //       style: const TextStyle(fontSize: 12),
                        //     ),
                        //     onPressed: () async {
                        //       final prefs =
                        //           await SharedPreferences.getInstance();

                        //       // 1. Xóa key lưu ảnh tổng Sa bàn trong SharedPreferences
                        //       await prefs.remove(
                        //         'saved_building_overview_image',
                        //       );

                        //       // 2. Xóa sạch cache RAM để Flutter không load lại ảnh đệm cũ
                        //       imageCache.clear();
                        //       imageCache.clearLiveImages();

                        //       // 3. Cập nhật giao diện trong Dialog và màn hình chính ngay lập tức
                        //       const String defaultImg =
                        //           'assets/images/default_tower.jpg'; // Hoặc 'assets/images/building.jpg'

                        //       setDialogState(() {
                        //         previewImage = defaultImg;
                        //       });

                        //       if (mounted) {
                        //         setState(() {
                        //           _overviewImage = defaultImg;
                        //         });
                        //       }
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_isEn ? 'Cancel' : 'Hủy'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isEn ? 'Save' : 'Lưu Thay Đổi'),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final newName = nameController.text.trim();
                    if (previewImage.startsWith('assets/')) {
                      await prefs.remove('saved_building_overview_image');
                    } else {
                      await prefs.setString(
                        'saved_building_overview_image',
                        previewImage,
                      );
                    }
                    if (newName.isNotEmpty) {
                      await prefs.setString(
                        'saved_building_project_name',
                        newName,
                      );
                    } else {
                      await prefs.remove('saved_building_project_name');
                    }
                    imageCache.clear();
                    imageCache.clearLiveImages();
                    if (!mounted) return;
                    setState(() {
                      _overviewImage = previewImage;
                      if (newName.isNotEmpty) {
                        _projectName = newName;
                      }
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isEn
                                ? 'Updated successfully!'
                                : '✅ Đã lưu cấu hình Sa Bàn thành công!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _makeImagePermanent(String pickedPath, String prefix) async {
    if (kIsWeb || pickedPath.startsWith('assets/')) return pickedPath;
    File file = File(pickedPath);
    if (!await file.exists()) return pickedPath;
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(pickedPath);
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await file.copy(p.join(appDir.path, fileName));
    return savedFile.path;
  }

  void _showManagementMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _isEn ? 'MANAGEMENT OPTIONS' : 'TÙY CHỌN QUẢN LÝ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF0284C7),
                  ),
                ),
                title: Text(
                  _isEn
                      ? '1. Manage Building Image'
                      : '1. Quản lý ảnh Sa Bàn (Building)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _isEn
                      ? 'Change main overview picture'
                      : 'Đổi hình ảnh sa bàn mặt bằng tổng',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(sheetContext); // Đóng menu chọn
                  _showOverviewImageDialog(); // Mở Dialog Mục 1
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    color: Color(0xFF0284C7),
                  ),
                ),
                title: Text(
                  _isEn ? '2. Manage Tower Images' : '2. Quản lý ảnh Các Tháp',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _isEn
                      ? 'Update images by range or all towers'
                      : 'Đổi ảnh theo dải hoặc danh sách từng tháp',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(sheetContext); // Đóng menu chọn
                  _showManageTowersDialog(
                    context,
                  ); // Mở Dialog Mục 2 (Dải tháp hiện tại)
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, [bool isPhone = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
                tooltip: 'Quay lại',
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
                tooltip: _isEn ? 'Management Options' : 'Tùy chọn quản lý',
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF0369A1),
                  size: 22,
                ),
                onPressed: () {
                  _showManagementMenu(); // 🟢 Mở Menu BottomSheet gồm 2 mục chọn riêng biệt
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 12.0 : 20.0,
                    vertical: 7.0,
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
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.domain_rounded,
                          size: 17,
                          color: Color(0xFF0369A1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _projectName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0369A1),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Thông tin',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        _isEn ? 'Building Info' : 'Thông Tin Tòa Nhà',
                      ),
                      content: Text(
                        '${_isEn ? "Building" : "Tòa nhà"}: $_projectName',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageTowersDialog(BuildContext context) {
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
                              ? 'Manage Tower Images'
                              : 'Quản Lý Ảnh Các Tháp',
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
                          text: _isEn ? 'By Range' : 'Theo Dải Tháp',
                        ),
                        Tab(
                          icon: const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 20,
                          ),
                          text: _isEn ? 'All Towers' : 'Tất Cả Tháp',
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
                                  ? 'Apply 1 image for multiple towers:'
                                  : 'Áp dụng 1 ảnh cho nhiều tháp:',
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
                                    ? 'Tower Range (e.g. 1-3 or 1-5, 8)'
                                    : 'Dải tháp (Ví dụ: 1-3 hoặc 1-5, 8)',
                                prefixIcon: const Icon(Icons.numbers_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: '1-3',
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
                                            fit: BoxFit.contain,
                                          )
                                        : Image.file(
                                            File(rangePreviewImage),
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
                                            'Chưa chọn ảnh cho dải tháp',
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
                                  try {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (image == null) {
                                      return;
                                    }
                                    String rawPath = kIsWeb
                                        ? Uri.decodeFull(image.path)
                                        : image.path;
                                    String permPath = await _makeImagePermanent(
                                      rawPath,
                                      'tower_range',
                                    );
                                    setDialogState(() {
                                      rangePreviewImage = permPath;
                                      errorMsg = '';
                                    });
                                  } catch (e) {
 //
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
                                  child: // 🟢 THAY TOÀN BỘ NÚT ELEVATEDBUTTON "ÁP DỤNG DẢI" TRONG DIALOG BẰNG CODE NÀY:
                                  ElevatedButton.icon(
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
                                      List<int> targetIndexes =
                                          _parseBuildingRangeInput(input);
                                      if (targetIndexes.isEmpty) {
                                        setDialogState(
                                          () => errorMsg = '⚠️ Vui lòng nhập dải tháp hợp lệ (VD: 1-4)!',
                                        );
                                        return;
                                      }
                                      if (rangePreviewImage.isEmpty) {
                                        setDialogState(
                                          () => errorMsg = '⚠️ Vui lòng chọn ảnh dùng chung trước!',
                                        );
                                        return;
                                      }
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      Map<String, String> updatedMap = {};
                                      for (int idx in targetIndexes) {
                                        int realIndex = idx - 1; // Quy đổi từ 1-based sang 0-based
                                        if (realIndex >= 0 &&
                                            realIndex <
                                                widget.buildings.length) {
                                          var b = widget.buildings[realIndex];
                                          String bName =
                                              b['name'] ?? b['title'] ?? '';
                                          String cleanKey = _cleanTowerKey(
                                            bName,
                                          );
                                          String storageKey = _getStorageKey(
                                            bName,
                                          );
                                          await prefs.setString(
                                            storageKey,
                                            rangePreviewImage,
                                          );
                                          updatedMap[cleanKey] =
                                              rangePreviewImage;
                                        }
                                      }
                                      imageCache.clear();
                                      imageCache.clearLiveImages();
                                      if (mounted) {
                                        setState(() {
                                          _overrideBuildingImages.addAll(
                                            updatedMap,
                                          );
                                          if (_selectedTowerKey.isNotEmpty) {
                                            String cleanSelected =
                                                _cleanTowerKey(
                                                  _selectedTowerKey,
                                                );
                                            if (updatedMap.containsKey(
                                              cleanSelected,
                                            )) {
                                              _selectedTowerImage =
                                                  updatedMap[cleanSelected]!;
                                            }
                                          }
                                        });
                                      }
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(
                                        color: Colors.orange,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                    icon: const Icon(Icons.restore, size: 18),
                                    label: Text(
                                      _isEn ? 'Restore Range' : 'Khôi Phục Dải',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    // onPressed: () async {
                                    //   String input = rangeController.text
                                    //       .trim();
                                    //   List<int> targetIndexes =
                                    //       _parseBuildingRangeInput(input);
                                    //   if (targetIndexes.isEmpty) {
                                    //     setDialogState(
                                    //       () => errorMsg = '⚠️ Vui lòng nhập dải tháp cần khôi phục!',
                                    //     );
                                    //     return;
                                    //   }
                                    //   final prefs =
                                    //       await SharedPreferences.getInstance();
                                    //   for (int idx in targetIndexes) {
                                    //     int realIndex = idx - 1;
                                    //     if (realIndex >= 0 &&
                                    //         realIndex <
                                    //             widget.buildings.length) {
                                    //       var b = widget.buildings[realIndex];
                                    //       String bName =
                                    //           b['name'] ?? b['title'] ?? '';
                                    //       String storageKey = _getStorageKey(
                                    //         bName,
                                    //       );
                                    //       await prefs.remove(storageKey);
                                    //       _overrideBuildingImages.remove(
                                    //         bName
                                    //             .replaceAll(' ', '_')
                                    //             .toUpperCase(),
                                    //       );
                                    //     }
                                    //   }
                                    //   imageCache.clear();
                                    //   imageCache.clearLiveImages();
                                    //   if (mounted) {
                                    //     setState(() {});
                                    //   }
                                    //   if (dialogContext.mounted) {
                                    //     Navigator.pop(dialogContext);
                                    //   }
                                    // },
                                    onPressed: () async {
                                      String input = rangeController.text
                                          .trim();
                                      List<int> targetIndexes =
                                          _parseBuildingRangeInput(input);
                                      if (targetIndexes.isEmpty) {
                                        setDialogState(
                                          () => errorMsg = '⚠️ Vui lòng nhập dải tháp cần khôi phục!',
                                        );
                                        return;
                                      }

                                      final prefs =
                                          await SharedPreferences.getInstance();

                                      for (int idx in targetIndexes) {
                                        int realIndex = idx - 1; // Quy đổi từ 1-based sang 0-based
                                        if (realIndex >= 0 &&
                                            realIndex <
                                                widget.buildings.length) {
                                          var b = widget.buildings[realIndex];
                                          String bName =
                                              b['name'] ?? b['title'] ?? '';

                                          String cleanKey = _cleanTowerKey(
                                            bName,
                                          ); // Key chuẩn hóa (vd: THAP_A)
                                          String storageKey = _getStorageKey(
                                            bName,
                                          );

                                          // 🟢 1. Xóa tất cả các Key liên quan đến từng tháp trong dải
                                          await prefs.remove(storageKey);
                                          await prefs.remove(
                                            'saved_tower_name_$cleanKey',
                                          );

                                          // 🟢 2. Xóa khỏi RAM state với cả 2 kiểu Key để đảm bảo sạch sẽ
                                          _overrideBuildingImages.remove(
                                            cleanKey,
                                          );
                                          _overrideBuildingImages.remove(
                                            bName
                                                .replaceAll(' ', '_')
                                                .toUpperCase(),
                                          );
                                          _overrideBuildingNames.remove(
                                            cleanKey,
                                          );
                                        }
                                      }

                                      // 🟢 3. Xóa cache đệm RAM ảnh của Flutter
                                      imageCache.clear();
                                      imageCache.clearLiveImages();

                                      if (mounted) {
                                        setState(() {
                                          // Nếu tháp đang chọn nằm trong dải vừa khôi phục -> Reset giao diện chọn mặt bằng
                                          _selectedTowerKey = '';
                                          _selectedTowerImage = '';
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
                        itemCount: widget.buildings.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final b = widget.buildings[index];
                          String bName = b['name'] ?? 'THÁP ${index + 1}';
                          String imgPath = _getBuildingImagePath(bName);
                          bool isCustomized = _overrideBuildingImages
                              .containsKey(
                                bName.replaceAll(' ', '_').toUpperCase(),
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
                                              'tower_tab2_${bName}_${isCustomized}_$imgPath',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(imgPath),
                                            key: ValueKey(
                                              'tower_tab2_${bName}_${isCustomized}_$imgPath',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bName,
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
                                  tooltip: 'Đổi ảnh tháp này',
                                  onPressed: () async {
                                    try {
                                      final ImagePicker picker = ImagePicker();
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 85,
                                          );
                                      if (image == null) return;
                                      String rawPath = kIsWeb
                                          ? Uri.decodeFull(image.path)
                                          : image.path;
                                      String cleanKey = _cleanTowerKey(bName);
                                      String storageKey = _getStorageKey(bName);
                                      String permPath =
                                          await _makeImagePermanent(
                                            rawPath,
                                            'tower_$cleanKey',
                                          );
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString(
                                        storageKey,
                                        permPath,
                                      );
                                      imageCache.clear();
                                      imageCache.clearLiveImages();
                                      if (mounted) {
                                        setState(() {
                                          _overrideBuildingImages[cleanKey] =
                                              permPath;
                                          if (_selectedTowerKey == cleanKey) {
                                            _selectedTowerImage = permPath;
                                          }
                                        });
                                      }
                                      setDialogState(() {});
                                    } catch (e) {
                                      //
                                    }
                                  },
                                ),
                                // IconButton(
                                //   icon: const Icon(
                                //     Icons.restore,
                                //     color: Colors.orange,
                                //     size: 20,
                                //   ),
                                //   tooltip: 'Khôi phục ảnh gốc',
                                //   onPressed: () async {
                                //     final prefs =
                                //         await SharedPreferences.getInstance();
                                //     String storageKey = _getStorageKey(bName);
                                //     await prefs.remove(storageKey);
                                //     imageCache.clear();
                                //     imageCache.clearLiveImages();
                                //     if (mounted) {
                                //       setState(() {
                                //         _overrideBuildingImages.remove(
                                //           bName
                                //               .replaceAll(' ', '_')
                                //               .toUpperCase(),
                                //         );
                                //       });
                                //     }
                                //     setDialogState(() {});
                                //   },
                                // ),
                                // IconButton(
                                //   icon: const Icon(
                                //     Icons.restore,
                                //     color: Colors.orange,
                                //     size: 20,
                                //   ),
                                //   tooltip: 'Khôi phục ảnh gốc',
                                //   onPressed: () async {
                                //     final prefs =
                                //         await SharedPreferences.getInstance();

                                //     // 🟢 1. Lấy CleanKey đã chuẩn hóa không dấu (VD: THAP_A)
                                //     String cleanKey = _cleanTowerKey(bName);
                                //     String storageKey = _getStorageKey(bName);

                                //     // 🟢 2. Xóa sạch trong SharedPreferences
                                //     await prefs.remove(storageKey);
                                //     await prefs.remove(
                                //       'saved_tower_name_$cleanKey',
                                //     );
                                //     await prefs.remove(
                                //       'custom_tower_img_tower_${cleanKey.toLowerCase()}',
                                //     );

                                //     // 🟢 3. Xóa Cache RAM ảnh đệm của Flutter
                                //     imageCache.clear();
                                //     imageCache.clearLiveImages();

                                //     // 🟢 4. Xóa sạch trong Map RAM (xóa cả Key không dấu và Key có dấu để tránh bỏ sót)
                                //     if (mounted) {
                                //       setState(() {
                                //         _overrideBuildingImages.remove(
                                //           cleanKey,
                                //         );
                                //         _overrideBuildingImages.remove(
                                //           bName
                                //               .replaceAll(' ', '_')
                                //               .toUpperCase(),
                                //         );
                                //         _overrideBuildingNames.remove(cleanKey);
                                //         _overrideBuildingNames.remove(
                                //           bName
                                //               .replaceAll(' ', '_')
                                //               .toUpperCase(),
                                //         );

                                //         // Nếu tháp này đang được chọn hiển thị ngoài màn hình -> Reset giao diện chọn
                                //         if (_selectedTowerKey == cleanKey) {
                                //           _selectedTowerKey = '';
                                //           _selectedTowerImage = '';
                                //         }
                                //       });
                                //     }

                                //     // 🟢 5. Ép Dialog cập nhật ngay lập tức thumbnail trong danh sách
                                //     setDialogState(() {});
                                //   },
                                // ),
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

  Widget _buildAdaptiveBuildingPanel(BuildContext context, bool isPhone) {
    double spacing = isPhone ? 4.0 : 12.0;
    List<int> allBuildingsLeds = [];
    bool isAnyTowerOn = false;
    for (var b in widget.buildings) {
      List<int> bLeds = _getBuildingLeds(b);
      allBuildingsLeds.addAll(bLeds);
      if (widget.isAnyLedOn(bLeds)) {
        isAnyTowerOn = true; // Chỉ cần 1 Tháp đang bật -> Đánh dấu CÓ THÁP BẬT
      }
    }
    allBuildingsLeds = allBuildingsLeds.toSet().toList();
    bool isBuildingMasterOn = isAnyTowerOn;
    return Container(
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
          SizedBox(height: isPhone ? 6 : 8),
          InkWell(
            onTap: () {
              if (allBuildingsLeds.isEmpty) return;
              bool targetState = !isBuildingMasterOn;
              widget.onToggleLeds(allBuildingsLeds, targetState);
              setState(() {
                _selectedTowerKey = '';
                _selectedTowerImage = '';
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
                gradient: isBuildingMasterOn
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
                  color: isBuildingMasterOn
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF0284C7),
                  width: isBuildingMasterOn ? 1.8 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isBuildingMasterOn
                        ? const Color(0xFFEC4899).withValues(alpha: 0.45)
                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                    blurRadius: isBuildingMasterOn ? 12 : 6,
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
                      color: isBuildingMasterOn
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFF0284C7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBuildingMasterOn
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      size: isPhone ? 13 : 15,
                      color: isBuildingMasterOn
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
                        isBuildingMasterOn
                            ? 'TẮT TỔNG TÒA NHÀ'
                            : 'BẬT TỔNG TÒA NHÀ',
                        style: TextStyle(
                          fontSize: isPhone ? 10.5 : 12.0,
                          fontWeight: FontWeight.bold,
                          color: isBuildingMasterOn
                              ? Colors.white
                              : const Color(0xFF0284C7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${allBuildingsLeds.length} p | ${isBuildingMasterOn ? "ĐANG BẬT" : "ĐANG TẮT"}',
                        style: TextStyle(
                          fontSize: isPhone ? 8.0 : 9.0,
                          fontWeight: FontWeight.w600,
                          color: isBuildingMasterOn
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
                          right: index == widget.buildings.length - 1
                              ? 0
                              : spacing,
                        ),
                        child: item,
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.buildings.length - 1
                            ? 0
                            : spacing,
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
    String bName = b['name'] ?? 'THÁP A';
    String cleanKey = _cleanTowerKey(bName);
    final bool isSelected = _selectedTowerKey == cleanKey;
    final List floorsInTower = b['floors'] ?? [];
    final bool canNavigateToFloors = floorsInTower.length > 1;
    return InkWell(
      onTap: () {
        String targetImagePath = _getBuildingImagePath(bName);
        widget.onToggleLeds(bLeds, !isOn);
        if (!mounted) return;
        setState(() {
          if (_selectedTowerKey == cleanKey) {
            _selectedTowerKey = '';
            _selectedTowerImage = '';
          } else {
            _selectedTowerKey = cleanKey;
            _selectedTowerImage = targetImagePath;
          }
        });
      },
      onLongPress: () {
        _showBuildingEditDialog(b);
      },
      onDoubleTap: canNavigateToFloors
          ? () async {
              String rawName = b['name'] ?? b['title'] ?? 'THÁP A';
              String towerSpecificImage = _getBuildingImagePath(rawName);
              if (towerSpecificImage.isEmpty ||
                  towerSpecificImage == 'assets/images/building.jpg') {
                String cleanKey = _cleanTowerKey(rawName);
                towerSpecificImage = await _resolveTowerImage(cleanKey);
              }
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FloorsListScreen(
                    buildingName: bName,
                    towerName: rawName, // 👈 Truyền đúng "THÁP D"
                    buildingImageConfig: towerSpecificImage, // 👈 Đã mang ảnh Penthouse chuẩn xác sang Floor screen
                    floors: b['floors'] ?? [],
                    ledStates: widget.ledStates,
                    onToggleLeds: widget.onToggleLeds,
                    isAnyLedOn: widget.isAnyLedOn,
                    extractLeds: widget.extractLeds,
                    selectedFilterType: widget.selectedFilterType,
                    configData: widget.configData,
                    currentLang: widget.currentLang,
                  ),
                ),
              );
              if (!mounted) return;
              setState(() {});
            }
          : () {},
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
                ? const Color(0xFF0284C7)
                : (isOn ? Colors.amberAccent : const Color(0xFFF472B6)),
            width: isSelected ? 2.5 : 1.2,
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
                      _getBuildingDisplayName(b['name'] ?? 'TÒA NHÀ'),
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
