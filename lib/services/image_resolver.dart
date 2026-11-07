import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
class ImageResolver {
  static Future<String> getActiveImagePath({
    required String projectId,
    required String imageKey,
    required String cloudUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isCustomKey = 'is_custom_${projectId}_$imageKey';
    final customPathKey = 'custom_path_${projectId}_$imageKey';
    final bool isCustom = prefs.getBool(isCustomKey) ?? false;
    final String? customPath = prefs.getString(customPathKey);
    if (isCustom && customPath != null && customPath.isNotEmpty) {
      final cleanPath = customPath.replaceAll('file://', '');
      if (customPath.startsWith('http') || File(cleanPath).existsSync()) {
        return customPath;
      }
    }
    return cloudUrl;
  }
  static Future<String> resolveImagePath({
    required String projectId,
    required String imageKey,
    required String defaultCloudUrl,
  }) async {
    return await getActiveImagePath(
      projectId: projectId,
      imageKey: imageKey,
      cloudUrl: defaultCloudUrl,
    );
  }
  static Future<void> saveCustomImage({
    required String projectId,
    required String imageKey,
    required String newFilePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_custom_${projectId}_$imageKey', true);
    await prefs.setString('custom_path_${projectId}_$imageKey', newFilePath);
  }
  static Future<void> resetToCloudImage({
    required String projectId,
    required String imageKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_custom_${projectId}_$imageKey');
    await prefs.remove('custom_path_${projectId}_$imageKey');
  }
}