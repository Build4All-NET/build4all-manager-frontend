// lib/features/owner/common/domain/entities/owner_project.dart

class OwnerProject {
  final int projectId;
  final String projectName;
  final String slug;

  final int linkId;
  final String status;
  final String appName;

  final String? apkUrl;
  final String? bundleUrl;
  final String? ipaUrl;

  final String? logoUrl;
  final String? androidPackageName;
  final String? iosBundleId;

  // ✅ NEW: build job status per platform
  final String? androidBuildStatus; // QUEUED | BUILDING | FAILED | SUCCESS ...
  final String? iosBuildStatus;
  final String? androidBuildError;
  final String? iosBuildError;

  OwnerProject({
    required this.projectId,
    required this.projectName,
    required this.slug,
    required this.apkUrl,
    required this.linkId,
    required this.status,
    required this.appName,
    required this.ipaUrl,
    required this.bundleUrl,
    required this.logoUrl,
    required this.androidPackageName,
    required this.iosBundleId,

    // ✅ NEW
    required this.androidBuildStatus,
    required this.iosBuildStatus,
    required this.androidBuildError,
    required this.iosBuildError,
  });

  String? get packageOrBundleId => androidPackageName ?? iosBundleId;
}
