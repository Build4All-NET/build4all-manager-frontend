class AppRequestDto {
  final int id; // backend doesn't send it => default 0
  final int ownerId; // backend sends adminId
  final int projectId;
  final String appName;
  final String status;
  final String slug;

  final String? apkUrl;
  final String? logoUrl;

  final int? ownerProjectLinkId;
  final String? manifestUrlHint;
  final String? runtimeConfigUrl;
  final int? currencyId;
  final String? message;

  const AppRequestDto({
    required this.id,
    required this.ownerId,
    required this.projectId,
    required this.appName,
    required this.status,
    required this.slug,
    this.apkUrl,
    this.logoUrl,
    this.ownerProjectLinkId,
    this.manifestUrlHint,
    this.runtimeConfigUrl,
    this.currencyId,
    this.message,
  });

  static int _toInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    return int.tryParse(v.toString()) ?? def;
  }

  static String _toStr(dynamic v, {String def = ''}) {
    if (v == null) return def;
    return v.toString();
  }

  static String? _toNullableStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory AppRequestDto.fromJson(Map<String, dynamic> j) {
    return AppRequestDto(
      id: _toInt(j['id'], def: 0), // not in response -> 0
      ownerId: _toInt(j['ownerId'] ?? j['adminId'], def: 0), // 👈 IMPORTANT
      projectId: _toInt(j['projectId'], def: 0),
      appName: _toStr(j['appName']),
      status: _toStr(j['status']),
      slug: _toStr(j['slug']),
      apkUrl: _toNullableStr(j['apkUrl']),
      logoUrl: _toNullableStr(j['logoUrl']),
      ownerProjectLinkId: j['ownerProjectLinkId'] == null
          ? null
          : _toInt(j['ownerProjectLinkId']),
      manifestUrlHint: _toNullableStr(j['manifestUrlHint']),
      runtimeConfigUrl: _toNullableStr(j['runtimeConfigUrl']),
      currencyId: j['currencyId'] == null ? null : _toInt(j['currencyId']),
      message: _toNullableStr(j['message']),
    );
  }
}
