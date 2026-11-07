import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/preload_service.dart';
class SyncService {
  final String gistApiUrl =
      'https://api.github.com/gists/532166906f27c570ff8b0c6890e3fcc2';
  Future<Map<String, dynamic>?> fetchAndSaveMasterConfig() async {
    try {
      const String baseRawUrl =
          'https://gist.githubusercontent.com/smartscalemodelcontroller-commits/532166906f27c570ff8b0c6890e3fcc2/raw/config.json';
      final String cacheBuster = DateTime.now().microsecondsSinceEpoch.toString();
      final Uri requestUri = Uri.parse('$baseRawUrl?nocache=$cacheBuster');
      final response = await http.get(
        requestUri,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      final String jsonContent = utf8.decode(response.bodyBytes);
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      if (jsonContent.contains('"A9"')) {
      } else {
      }
      ConfigService.activeSyncVersion = cacheBuster;
      final String currentIp = await ConfigService.getSavedIp() ?? '';
      await ConfigService.saveConfig(currentIp, jsonContent);
      return decoded;
    } catch (e) {
      return null;
    }
  }
  List<String> _extractAllUrlsFromMap(Map<String, dynamic> map) {
    final Set<String> urls = {};
    void extract(dynamic value) {
      if (value is String) {
        if (value.startsWith('http://') || value.startsWith('https://')) {
          if (value.contains('.webp') ||
              value.contains('.png') ||
              value.contains('.jpg') ||
              value.contains('.jpeg')) {
            urls.add(value.trim());
          }
        }
      } else if (value is Map) {
        value.values.forEach(extract);
      } else if (value is List) {
        value.forEach(extract);
      }
    }
    extract(map);
    return urls.toList();
  }
  Future<void> _preloadUrlList(List<String> urls) async {
    try {
      final cacheManager = DefaultCacheManager();
      final futures = urls.map((url) async {
        try {
          await cacheManager.downloadFile(url);
        } catch (_) {}
      });
      await Future.wait(futures);
    } catch (e) {
      //
    }
  }
  Future<bool> syncSmartUpdate() async {
    try {
      final freshConfig = await fetchAndSaveMasterConfig();
      if (freshConfig == null) {
        return false;
      }
      final List<String> allUrls = _extractAllUrlsFromMap(freshConfig);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final List<String> timestampedUrls = allUrls.map((url) {
        return url.contains('?') ? '$url&v=$timestamp' : '$url?v=$timestamp';
      }).toList();
      await _preloadUrlList(timestampedUrls);
      return true;
    } catch (e) {
      return false;
    }
  }
Future<bool> syncCleanMasterReset() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_building_project_name');
    await prefs.remove('saved_building_overview_image');
    await prefs.remove('saved_overview_image');
    await prefs.remove('saved_connect_title');
    await prefs.remove('saved_connect_bg');
    final Set<String> keys = prefs.getKeys();
    int removedKeysCount = 0;
    for (String key in keys) {
      if (key.startsWith('saved_tower_') || 
          key.startsWith('saved_floor_') || 
          key.startsWith('custom_tower_img_') ||
          key.startsWith('custom_path_')) {
        await prefs.remove(key);
        removedKeysCount++;
      }
    }
    debugPrint('🧹 [SYNC RESET] Đã dọn dẹp $removedKeysCount key ảnh/tên custom.');
    final String resetVersion = DateTime.now().millisecondsSinceEpoch.toString();
    ConfigService.activeSyncVersion = resetVersion;
    await prefs.setString('last_master_reset_version', resetVersion);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
    final masterConfig = await fetchAndSaveMasterConfig();
    if (masterConfig == null) {
      return false;
    }
    final List<String> rawUrls = _extractUrlsFromCatalog(masterConfig);
    final List<String> versionedUrls = rawUrls.map((url) {
      if (!url.startsWith('http')) return url;
      final cleanUrl = url.split(RegExp(r'[?&]v=')).first;
      final separator = cleanUrl.contains('?') ? '&' : '?';
      return '$cleanUrl${separator}v=$resetVersion';
    }).toList();
    try {
      await PreloadService.cacheAllBuildingImages(
        imageUrls: versionedUrls,
        batchSize: 5,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
     //
    }
    return true;
  } catch (e) {
    return false;
  }
}
  List<String> _extractUrlsFromCatalog(dynamic data) {
    final Set<String> urls = {};
    void extract(dynamic element) {
      if (element is String) {
        final lower = element.toLowerCase();
        if (element.startsWith('http') &&
            (lower.endsWith('.png') ||
                lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.webp') ||
                lower.endsWith('.gif'))) {
          urls.add(element.trim());
        }
      } else if (element is Map) {
        for (var value in element.values) {
          extract(value);
        }
      } else if (element is List) {
        for (var item in element) {
          extract(item);
        }
      }
    }
    extract(data);
    return urls.toList();
  }
  Future<void> syncExcelConfigOnly() async {
    await fetchAndSaveMasterConfig();
  }
  Future<void> syncAllImagesCloud() async {
    await syncCleanMasterReset();
  }
  Future<void> syncMasterAll() async {
    await syncCleanMasterReset();
  }
  Future<bool> syncSingleImageKey(String imageKey, {String? projectId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String pId = projectId ?? 'default_project';
      final String customPathKey = 'custom_path_${pId}_$imageKey';
      final String isCustomKey = 'is_custom_${pId}_$imageKey';
      final String legacyKey = 'custom_img_$imageKey';
      final String? path =
          prefs.getString(customPathKey) ?? prefs.getString(legacyKey);
      if (path != null && !path.startsWith('http')) {
        try {
          final file = File(path.replaceAll('file://', ''));
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (_) {}
      }
      await prefs.remove(customPathKey);
      await prefs.remove(isCustomKey);
      await prefs.remove(legacyKey);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      return true;
    } catch (e) {
      return false;
    }
  }
  Future<void> syncSingleImageByKey(String imageKey) async {
    await syncSingleImageKey(imageKey);
  }
  static Future<void> syncSingleImageUrl({
    required String projectId,
    required String imageKey,
    required String cloudImageUrl,
  }) async {
    if (cloudImageUrl.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_custom_${projectId}_$imageKey');
      await prefs.remove('custom_path_${projectId}_$imageKey');
      await prefs.remove('custom_img_$imageKey');
      await prefs.remove('saved_overview_image');
      final Uri? parsedUri = Uri.tryParse(cloudImageUrl);
      final String cleanCacheKey = parsedUri != null
          ? '${parsedUri.scheme}://${parsedUri.host}${parsedUri.path}'
          : cloudImageUrl;
      await DefaultCacheManager().removeFile(cleanCacheKey);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      //
    }
  }
  static Map<String, String> extractSyncableItems(
    Map<String, dynamic>? configMap,
  ) {
    final Map<String, String> items = {};
    if (configMap == null || configMap.isEmpty) return items;
    Map<String, dynamic> targetMap = configMap;
    if (!configMap.containsKey('room_layouts') &&
        !configMap.containsKey('buildings_info')) {
      if (configMap.containsKey('projects') && configMap['projects'] is Map) {
        final Map projectsMap = configMap['projects'];
        if (projectsMap.isNotEmpty &&
            projectsMap.values.first is Map<String, dynamic>) {
          targetMap = projectsMap.values.first as Map<String, dynamic>;
        }
      } else if (configMap.containsKey('project') &&
          configMap['project'] is Map<String, dynamic>) {
        targetMap = configMap['project'] as Map<String, dynamic>;
      }
    }
    final String overviewUrl =
        (targetMap['overview_url'] ??
                targetMap['overview_image'] ??
                targetMap['image_url'] ??
                targetMap['overview'] ??
                '')
            .toString();
    if (overviewUrl.isNotEmpty) {
      items['overview_image'] = overviewUrl;
    }
    final dynamic rawBuildings =
        targetMap['buildings_info'] ??
        targetMap['buildings'] ??
        targetMap['towers'];
    if (rawBuildings is List) {
      for (var b in rawBuildings) {
        if (b is Map) {
          final String tId = (b['id'] ?? b['tower_id'] ?? b['key'] ?? '')
              .toString();
          final String tUrl =
              (b['image_url'] ?? b['overview_url'] ?? b['url'] ?? '')
                  .toString();
          if (tId.isNotEmpty && tUrl.isNotEmpty) {
            items[tId] = tUrl;
          }
        }
      }
    }
    final dynamic rawLayouts =
        targetMap['room_layouts'] ?? targetMap['layouts'];
    if (rawLayouts is Map) {
      rawLayouts.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          final String keyStr = key.toString().toLowerCase().trim();
          final String layoutKey = keyStr.startsWith('layout_')
              ? keyStr
              : "layout_$keyStr";
          items[layoutKey] = value.toString().trim();
        }
      });
    }
    return items;
  }
  Future<void> runCacheDiagnostic({required String currentUiUrl}) async {
    final freshConfig = await fetchAndSaveMasterConfig();
    if (freshConfig == null) {
      return;
    }
    String? cloudBg;
    if (freshConfig.containsKey('assets') && freshConfig['assets'] is Map) {
      cloudBg = freshConfig['assets']['background']?.toString();
    }
    try {
      await DefaultCacheManager().emptyCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      //
    }
    if (cloudBg != null && cloudBg.startsWith('http')) {
      final String testTimestamp = DateTime.now().millisecondsSinceEpoch
          .toString();
      final String cleanUrl = cloudBg.split(RegExp(r'[?&]v=')).first;
      final String testUrl = '$cleanUrl?v=$testTimestamp';
      try {
        final File file = await DefaultCacheManager().getSingleFile(testUrl);
        final bool exists = await file.exists();
        final int fileSize = exists ? await file.length() : 0;
        if (exists && fileSize > 0) {
        } else {
        }
      } catch (e) {
        //
      }
    } else {
    }
  }
}
