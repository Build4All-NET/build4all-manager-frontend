// lib/features/owner/common/data/models/owner_project_dto.dart
import '../../domain/entities/owner_project.dart';

class OwnerProjectDto {
  final int projectId;
  final String projectName;
  final String slug;
  final String? apkUrl;

  // NEW:
  final int linkId;
  final String status;
  final String appName;
  final String? ipaUrl;
  final String? bundleUrl;

  // Optional (future/backward-compatible):
  final String? logoUrl;

  final String? androidPackageName;
  final String? iosBundleId;


  OwnerProjectDto({
    required this.projectId,
    required this.projectName,
    required this.slug,
    this.apkUrl,
    required this.linkId,
    required this.status,
    required this.appName,
    this.ipaUrl,
    this.bundleUrl,
    this.logoUrl,
    this.androidPackageName,
    this.iosBundleId,
    
  });

  factory OwnerProjectDto.fromJson(Map<String, dynamic> j) => OwnerProjectDto(
        projectId: j['projectId'] ?? 0,
        projectName: (j['projectName'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        apkUrl: j['apkUrl']?.toString(),
        linkId: (j['linkId'] ?? 0) as int,
        status: (j['status'] ?? 'UNKNOWN').toString(),
        appName: (j['appName'] ?? '').toString(),
        ipaUrl: j['ipaUrl']?.toString(),
        bundleUrl: j['bundleUrl']?.toString(),
        logoUrl: j['logoUrl']?.toString(), // safe if backend doesn’t send it
        androidPackageName: j['androidPackageName']?.toString(),
iosBundleId: j['iosBundleId']?.toString(),

      );

  OwnerProject toEntity() => OwnerProject(
        projectId: projectId,
        projectName: projectName,
        slug: slug,
        apkUrl: apkUrl,
        linkId: linkId,
        status: status,
        appName: appName,
        ipaUrl: ipaUrl,
        bundleUrl: bundleUrl,
        logoUrl: logoUrl,
      );
}
