class AppVersion {
  final String version;
  final bool force;
  final String? content;
  final String? downloadUrl;

  const AppVersion({
    required this.version,
    this.force = false,
    this.content,
    this.downloadUrl,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => AppVersion(
        version: json['version'] as String,
        force: json['force'] == true || json['force'] == 1,
        content: json['content'] as String?,
        downloadUrl: json['downloadUrl'] as String?,
      );
}