class AppRequestDto {
  final int id;
  final int ownerId;
  final int projectId;
  final String appName;
  final String status;
  final String slug;
  final String? apkUrl;
  final String? bundleUrl;
  final String? ipaUrl;
  final String? logoUrl;

  // extra new fields (optional)
  final int? ownerProjectLinkId;
  final String? manifestUrlHint;
  final String? runtimeConfigUrl;

  AppRequestDto({
    required this.id,
    required this.ownerId,
    required this.projectId,
    required this.appName,
    required this.status,
    required this.slug,
    this.apkUrl,
    this.bundleUrl,
    this.ipaUrl,
    this.logoUrl,
    this.ownerProjectLinkId,
    this.manifestUrlHint,
    this.runtimeConfigUrl,
  });

  factory AppRequestDto.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v, {int def = 0}) =>
        int.tryParse((v ?? def).toString()) ?? def;

    String toStr(dynamic v) => (v ?? '').toString();

    // Supports both:
    // - classic AppRequest row: {id, ownerId, projectId, appName, status, slug, apkUrl...}
    // - auto endpoint response: {adminId, projectId, ownerProjectLinkId, slug, appName, status, apkUrl, logoUrl, manifestUrlHint, runtimeConfigUrl...}
    final owner = j.containsKey('ownerId') ? j['ownerId'] : j['adminId'];

    return AppRequestDto(
      id: toInt(j['id'], def: 0),
      ownerId: toInt(owner, def: 0),
      projectId: toInt(j['projectId'], def: 0),
      appName: toStr(j['appName']),
      status: toStr(j['status']).isEmpty ? 'APPROVED' : toStr(j['status']),
      slug: toStr(j['slug']),
      apkUrl: toStr(j['apkUrl']).isEmpty ? null : toStr(j['apkUrl']),
      bundleUrl: toStr(j['bundleUrl']).isEmpty ? null : toStr(j['bundleUrl']),
      ipaUrl: toStr(j['ipaUrl']).isEmpty ? null : toStr(j['ipaUrl']),
      logoUrl: toStr(j['logoUrl']).isEmpty ? null : toStr(j['logoUrl']),
      ownerProjectLinkId: j['ownerProjectLinkId'] == null
          ? null
          : toInt(j['ownerProjectLinkId'], def: 0),
      manifestUrlHint: toStr(j['manifestUrlHint']).isEmpty
          ? null
          : toStr(j['manifestUrlHint']),
      runtimeConfigUrl: toStr(j['runtimeConfigUrl']).isEmpty
          ? null
          : toStr(j['runtimeConfigUrl']),
    );
  }

  // if you have an entity mapper:
  // AppRequest toEntity() => AppRequest(...); // keep your existing logic
}
