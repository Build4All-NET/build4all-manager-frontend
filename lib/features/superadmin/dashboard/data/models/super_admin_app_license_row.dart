class SuperAdminAppLicenseRow {
  final int aupId;

  final String appName;
  final String? slug;
  final String? appStatus;

  final int? adminId;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerUsername;

  final int? projectId;
  final String? projectName;

  final String? planCode;
  final String? planName;
  final String? subscriptionStatus;
  final DateTime? periodEnd;
  final int? daysLeft;

  final int? usersAllowed;
  final int? activeUsers;
  final int? usersRemaining;

  final bool? requiresDedicatedServer;
  final bool? dedicatedInfraReady;

  final bool? canAccessDashboard;
  final String? blockingReason;

  final String? upgradeRequestStatus;

  const SuperAdminAppLicenseRow({
    required this.aupId,
    required this.appName,
    this.slug,
    this.appStatus,
    this.adminId,
    this.ownerName,
    this.ownerEmail,
    this.ownerUsername,
    this.projectId,
    this.projectName,
    this.planCode,
    this.planName,
    this.subscriptionStatus,
    this.periodEnd,
    this.daysLeft,
    this.usersAllowed,
    this.activeUsers,
    this.usersRemaining,
    this.requiresDedicatedServer,
    this.dedicatedInfraReady,
    this.canAccessDashboard,
    this.blockingReason,
    this.upgradeRequestStatus,
  });

  factory SuperAdminAppLicenseRow.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase().trim();
      if (s == 'true') return true;
      if (s == 'false') return false;
      return null;
    }

    return SuperAdminAppLicenseRow(
      aupId: parseInt(json['aupId']) ?? 0,
      appName: (json['appName'] ?? '').toString(),
      slug: json['slug']?.toString(),
      appStatus: json['appStatus']?.toString(),
      adminId: parseInt(json['adminId']),
      ownerName: json['ownerName']?.toString(),
      ownerEmail: json['ownerEmail']?.toString(),
      ownerUsername: json['ownerUsername']?.toString(),
      projectId: parseInt(json['projectId']),
      projectName: json['projectName']?.toString(),
      planCode: json['planCode']?.toString(),
      planName: json['planName']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      periodEnd: parseDate(json['periodEnd']),
      daysLeft: parseInt(json['daysLeft']),
      usersAllowed: parseInt(json['usersAllowed']),
      activeUsers: parseInt(json['activeUsers']),
      usersRemaining: parseInt(json['usersRemaining']),
      requiresDedicatedServer: parseBool(json['requiresDedicatedServer']),
      dedicatedInfraReady: parseBool(json['dedicatedInfraReady']),
      canAccessDashboard: parseBool(json['canAccessDashboard']),
      blockingReason: json['blockingReason']?.toString(),
      upgradeRequestStatus: json['upgradeRequestStatus']?.toString(),
    );
  }
}