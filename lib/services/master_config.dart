class MasterConfig {
  final String firmwareVersion;
  final List<ProjectConfig> projects;
  MasterConfig({required this.firmwareVersion, required this.projects});
  factory MasterConfig.fromJson(Map<String, dynamic> json) {
    return MasterConfig(
      firmwareVersion: json['firmware_info']?['version'] ?? '',
      projects: (json['projects'] as List)
          .map((p) => ProjectConfig.fromJson(p))
          .toList(),
    );
  }
}
class ProjectConfig {
  final String projectId;
  final String name;
  final String passcode;
  final String lanIp;
  final String mqttTopicPub;
  final String mqttTopicSub;
  final Map<String, dynamic> projectData; // Chứa căn hộ, phòng, ảnh...
  ProjectConfig.fromJson(Map<String, dynamic> json)
      : projectId = json['project_info']['project_id'],
        name = json['project_info']['name'],
        passcode = json['project_info']['passcode'],
        lanIp = json['project_info']['lan_ip'],
        mqttTopicPub = json['project_info']['mqtt_topic_pub'],
        mqttTopicSub = json['project_info']['mqtt_topic_sub'],
        projectData = json;
}