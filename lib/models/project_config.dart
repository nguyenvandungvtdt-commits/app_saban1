class ProjectConfig {
  final String projectName;
  final String version;
  final String description;
  final String backgroundImage;
  final String overviewImage;
  final String buildingImage;
  final String floorImage;
  final String roomImage;
  final Map<String, String> customFloors;
  final List<dynamic> rawData;
  final Map<String, dynamic> firmwareInfo;
  final List<dynamic> activeEffects;
  final Map<String, dynamic> uiTheme;
  final Map<String, dynamic> buildingsInfo;
  ProjectConfig({
    required this.projectName,
    required this.version,
    required this.description,
    required this.backgroundImage,
    required this.overviewImage,
    required this.buildingImage,
    required this.floorImage,
    required this.roomImage,
    required this.customFloors,
    required this.rawData,
    required this.firmwareInfo,
    required this.activeEffects,
    required this.uiTheme,
    required this.buildingsInfo,
  });
  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] ?? {};
    final projectInfo = json['project_info'] ?? {};
    return ProjectConfig(
      projectName: projectInfo['name'] ?? json['p'] ?? 'Dự Án Sa Bàn',
      version: projectInfo['version'] ?? '1.0.0',
      description: projectInfo['description'] ?? '',
      backgroundImage: assets['background'] ?? 'assets/images/background.png',
      overviewImage: assets['overview'] ?? 'assets/images/overview.jpg',
      buildingImage: assets['building_default'] ?? 'assets/images/building.jpg',
      floorImage: assets['floor_default'] ?? 'assets/images/floor.jpg',
      roomImage: assets['room_default'] ?? 'assets/images/floor.jpg',
      customFloors: Map<String, String>.from(assets['custom_floors'] ?? {}),
      rawData: json['d'] ?? [],
      firmwareInfo: Map<String, dynamic>.from(json['firmware_info'] ?? {}),
      activeEffects: List<dynamic>.from(json['active_effects'] ?? []),
      uiTheme: Map<String, dynamic>.from(json['ui_theme'] ?? {}),
      buildingsInfo: Map<String, dynamic>.from(json['buildings_info'] ?? {}),
    );
  }
  String getFloorImage(String buildingName, String floorName) {
    String key = '${buildingName}_$floorName';
    return customFloors[key] ?? floorImage;
  }
  Map<String, dynamic>? getBuildingInfo(String buildingName) {
    return buildingsInfo[buildingName];
  }
}