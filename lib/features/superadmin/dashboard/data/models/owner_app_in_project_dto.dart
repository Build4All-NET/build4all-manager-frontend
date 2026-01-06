class OwnerAppInProjectDto {
  final int id; // AdminUserProject id
  final String slug;
  final String appName;
  final String status;
  final String? apkUrl;
  final String? ipaUrl;
  final String? bundleUrl;

  OwnerAppInProjectDto({
    required this.id,
    required this.slug,
    required this.appName,
    required this.status,
    this.apkUrl,
    this.ipaUrl,
    this.bundleUrl,
  });

  factory OwnerAppInProjectDto.fromJson(Map<String, dynamic> json) {
    return OwnerAppInProjectDto(
      id: (json['id'] as num).toInt(),
      slug: (json['slug'] ?? '').toString(),
      appName: (json['appName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      apkUrl: json['apkUrl']?.toString(),
      ipaUrl: json['ipaUrl']?.toString(),
      bundleUrl: json['bundleUrl']?.toString(),
    );
  }
}
