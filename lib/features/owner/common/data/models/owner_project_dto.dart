import '../../domain/entities/owner_project.dart';

class OwnerProjectDto {
  final int projectId;
  final String projectName;
  final String slug;
  final String? apkUrl;

  final int linkId;
  final String status; // MUST come from backend
  final String appName;
  final String? ipaUrl;
  final String? bundleUrl;

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

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    final s = _asNullableString(v);
    return s ?? fallback;
  }

  factory OwnerProjectDto.fromJson(Map<String, dynamic> j) {
    // logo key variations
    final logo = _asNullableString(
      j['logoUrl'] ??
          j['logo_url'] ??
          j['logo'] ??
          j['projectLogo'] ??
          j['projectLogoUrl'] ??
          j['project_logo_url'],
    );

    // linkId variations
    final link = _asInt(
      j['linkId'] ?? j['ownerProjectLinkId'] ?? j['aupId'] ?? j['id'],
    );

    // ✅ status variations (IMPORTANT)
    // If backend uses a different key name, we still pick it.
    final statusVal = _asString(
      j['status'] ??
          j['appStatus'] ??
          j['buildStatus'] ??
          j['envStatus'] ??
          j['environmentStatus'] ??
          j['environment'] ??
          j['state'],
      fallback: 'UNKNOWN',
    );

    return OwnerProjectDto(
      projectId: _asInt(j['projectId'] ?? j['id']),
      projectName: _asString(j['projectName'] ?? j['name']),
      slug: _asString(j['slug']),
      apkUrl: _asNullableString(j['apkUrl'] ?? j['apk_url']),
      linkId: link,
      status: statusVal,
      appName: _asString(j['appName'] ?? j['displayName']),
      ipaUrl: _asNullableString(j['ipaUrl'] ?? j['ipa_url']),
      bundleUrl: _asNullableString(j['bundleUrl'] ?? j['bundle_url']),
      logoUrl: logo,
      androidPackageName: _asNullableString(
        j['androidPackageName'] ??
            j['android_package_name'] ??
            j['packageName'],
      ),
      iosBundleId: _asNullableString(
        j['iosBundleId'] ?? j['ios_bundle_id'] ?? j['bundleId'],
      ),
    );
  }

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
        androidPackageName: androidPackageName,
        iosBundleId: iosBundleId,
      );
}
