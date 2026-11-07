import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
class ConfigService {
  static const String _keyIp = 'esp32_ip';
  static const String _keyJsonConfig = 'esp32_json_config';
  static String activeSyncVersion = '';
  static Future<String> getActiveSyncVersion() async {
    if (activeSyncVersion.isNotEmpty) return activeSyncVersion;
    final prefs = await SharedPreferences.getInstance();
    activeSyncVersion = prefs.getString('last_master_reset_version') ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return activeSyncVersion;
  }
  static Future<void> setActiveSyncVersion(String newVersion) async {
    activeSyncVersion = newVersion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_master_reset_version', newVersion);
  }
  static Future<void> saveConfig(String ip, String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp, ip);
    await prefs.setString(_keyJsonConfig, jsonString);
  }
  static Future<String?> getSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIp);
  }
  static Future<String?> getSavedJsonConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJsonConfig);
  }
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIp);
    await prefs.remove(_keyJsonConfig);
    debugPrint('🧹 [CACHE] Đã xóa sạch cấu hình JSON cũ!');
  }
  static Map<String, String> parseDynamicFlatFloorUrls(
      Map<String, dynamic> rawUploadedAssets) {
    final Map<String, String> flatUrls = {};
    rawUploadedAssets.forEach((assetKey, url) {
      if (url == null || url.toString().trim().isEmpty) return;
      final keyLower = assetKey.toLowerCase().trim();
      if (RegExp(r'^tower_[a-z]_fl\d+$').hasMatch(keyLower)) {
        flatUrls[keyLower] = url.toString();
      }
    });
    rawUploadedAssets.forEach((assetKey, url) {
      if (url == null || url.toString().trim().isEmpty) return;
      final keyLower = assetKey.toLowerCase().trim();
      final match =
          RegExp(r'floor_([\d_]+)_tower_([a-z]+)').firstMatch(keyLower);
      if (match != null) {
        final rawFloors = match.group(1)!; // "19_22"
        final rawTowers = match.group(2)!; // "ae"
        List<int> floors = [];
        if (rawFloors.contains('_')) {
          final parts = rawFloors
              .split('_')
              .map((p) => int.tryParse(p))
              .whereType<int>()
              .toList();
          if (parts.length == 2) {
            floors = List.generate(
                parts[1] - parts[0] + 1, (i) => parts[0] + i);
          }
        } else if (int.tryParse(rawFloors) != null) {
          floors = [int.parse(rawFloors)];
        }
        for (final t in rawTowers.split('')) {
          for (final f in floors) {
            final key = 'tower_${t}_fl$f';
            flatUrls.putIfAbsent(key, () => url.toString());
          }
        }
      }
    });
    return flatUrls;
  }
  static Future<Map<String, dynamic>?> getFlatFloorUrls({
    String? targetProjectId,
  }) async {
    try {
      final String? jsonString = await getSavedJsonConfig();
      if (jsonString == null || jsonString.isEmpty) return null;
      final Map<String, dynamic> fullConfig = json.decode(jsonString);
      final String activeProjId =
          targetProjectId ?? fullConfig['active_project_id'] ?? '';
      Map<String, dynamic>? rawAssetsDict;
      final rawProjects = fullConfig['projects'];
      if (rawProjects is List) {
        for (var item in rawProjects) {
          if (item is Map) {
            final String? pId =
                item['project_info']?['project_id']?.toString() ??
                    item['project_id']?.toString();
            if (activeProjId.isEmpty || pId == activeProjId) {
              rawAssetsDict = (item['uploaded_assets'] ??
                      item['smart_floors']?['flat_floor_urls'])
                  as Map<String, dynamic>?;
              break;
            }
          }
        }
      } else if (rawProjects is Map) {
        final targetProj = rawProjects[activeProjId] as Map?;
        rawAssetsDict = (targetProj?['uploaded_assets'] ??
                targetProj?['smart_floors']?['flat_floor_urls'])
            as Map<String, dynamic>?;
      }
      rawAssetsDict ??= (fullConfig['uploaded_assets'] ??
              fullConfig['smart_floors']?['flat_floor_urls'])
          as Map<String, dynamic>?;
      if (rawAssetsDict != null) {
        return parseDynamicFlatFloorUrls(rawAssetsDict);
      }
    } catch (e) {
      debugPrint('❌ [CONFIG_SERVICE_ERROR] Lỗi: $e');
    }
    return null;
  }
  static Future<String> getActiveProjectId() async {
    try {
      final String? jsonString = await getSavedJsonConfig();
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> fullConfig = json.decode(jsonString);
        return fullConfig['active_project_id']?.toString() ?? 'dongvancong_1';
      }
    } catch (_) {}
    return 'dongvancong_1';
  }
  static Future<Map<String, dynamic>> getRoomLayouts({
    String? targetProjectId,
  }) async {
    final Map<String, dynamic> resultMap = {};
    try {
      final String? jsonString = await getSavedJsonConfig();
      if (jsonString == null || jsonString.isEmpty) return resultMap;
      final Map<String, dynamic> fullConfig = json.decode(jsonString);
      final String activeProjId =
          targetProjectId ?? fullConfig['active_project_id'] ?? '';
      Map<String, dynamic>? rawRoomLayouts;
      final rawProjects = fullConfig['projects'];
      if (rawProjects is Map) {
        final targetProj = rawProjects[activeProjId] as Map?;
        rawRoomLayouts = targetProj?['room_layouts'] as Map<String, dynamic>?;
      } else if (rawProjects is List) {
        for (var item in rawProjects) {
          if (item is Map) {
            final String? pId =
                item['project_info']?['project_id']?.toString() ??
                    item['project_id']?.toString();
            if (activeProjId.isEmpty || pId == activeProjId) {
              rawRoomLayouts = item['room_layouts'] as Map<String, dynamic>?;
              break;
            }
          }
        }
      }
      rawRoomLayouts ??= fullConfig['room_layouts'] as Map<String, dynamic>?;
      if (rawRoomLayouts != null) {
        rawRoomLayouts.forEach((key, val) {
          if (val != null && val.toString().isNotEmpty) {
            resultMap[key.toString().toUpperCase().trim()] = val.toString();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ [CONFIG_SERVICE] Lỗi getRoomLayouts: $e');
    }
    return resultMap;
  }
}