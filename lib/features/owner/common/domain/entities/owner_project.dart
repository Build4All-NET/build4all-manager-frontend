// lib/features/owner/common/domain/entities/owner_project.dart
class OwnerProject {
  final int projectId;
  final String projectName;
  final String slug;
  final String? apkUrl;

  final int linkId;
  final String status; // e.g., ACTIVE / IN_PRODUCTION
  final String appName; // display name
  final String? ipaUrl;
  final String? bundleUrl;

  // Optional: shown in grid if present (can be relative or absolute)
  final String? logoUrl;
  final String? androidPackageName;
final String? iosBundleId;


  const OwnerProject({
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

  bool get isApkReady => (apkUrl != null && apkUrl!.isNotEmpty);
  bool get isInProduction => status.toUpperCase().contains('PRODUCTION');
  bool get hasLogo => (logoUrl != null && logoUrl!.trim().isNotEmpty);
  
  String? get packageOrBundleId =>
    (androidPackageName?.trim().isNotEmpty ?? false)
        ? androidPackageName
        : (iosBundleId?.trim().isNotEmpty ?? false)
            ? iosBundleId
            : null;


}
