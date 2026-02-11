// lib/features/owner/app_build/data/models/build_status_models.dart

class PlatformBuildStatus {
  final String? status; // e.g. SUCCESS / RUNNING / FAILED / QUEUED
  final String? apkUrl; // Android only
  final String? aabUrl; // Android only
  final String? ipaUrl; // iOS only
  final String? error; // error message if FAILED
  final DateTime? lastUpdated;

  const PlatformBuildStatus({
    this.status,
    this.apkUrl,
    this.aabUrl,
    this.ipaUrl,
    this.error,
    this.lastUpdated,
  });

  factory PlatformBuildStatus.fromJson(Map<String, dynamic> json) {
    return PlatformBuildStatus(
      status: json['status'] as String?,
      apkUrl: json['apkUrl'] as String?,
      aabUrl: json['aabUrl'] as String?,
      ipaUrl: json['ipaUrl'] as String?,
      error: json['error'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'apkUrl': apkUrl,
      'aabUrl': aabUrl,
      'ipaUrl': ipaUrl,
      'error': error,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

class BuildStatusResponse {
  final int? linkId; // or projectId depending on backend
  final PlatformBuildStatus? android;
  final PlatformBuildStatus? ios;

  const BuildStatusResponse({
    this.linkId,
    this.android,
    this.ios,
  });

  factory BuildStatusResponse.fromJson(Map<String, dynamic> json) {
    return BuildStatusResponse(
      linkId: json['linkId'] as int?,
      android: json['android'] != null
          ? PlatformBuildStatus.fromJson(
              json['android'] as Map<String, dynamic>,
            )
          : null,
      ios: json['ios'] != null
          ? PlatformBuildStatus.fromJson(
              json['ios'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkId': linkId,
      'android': android?.toJson(),
      'ios': ios?.toJson(),
    };
  }
}
