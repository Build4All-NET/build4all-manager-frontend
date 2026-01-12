import 'dart:convert';
import '../../domain/entities/app_publish_request_admin.dart';
import '../../domain/entities/publisher_profile.dart';
import 'publisher_profile_model.dart';

class AppPublishRequestAdminModel {
  final int id;
  final int? aupId;
  final String? appName;

  final String platform;
  final String store;
  final String status;

  final DateTime? requestedAt;
  final DateTime? reviewedAt;

  final String? packageNameSnapshot;
  final String? bundleIdSnapshot;

  final String shortDescription;
  final String fullDescription;
  final String category;

  final String pricing;
  final bool contentRatingConfirmed;

  final String? appIconUrl;
  final List<String> screenshotsUrls;

  final String? adminNotes;
  final PublisherProfileModel? publisherProfile;

  const AppPublishRequestAdminModel({
    required this.id,
    required this.aupId,
    required this.appName,
    required this.platform,
    required this.store,
    required this.status,
    required this.requestedAt,
    required this.reviewedAt,
    required this.packageNameSnapshot,
    required this.bundleIdSnapshot,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.pricing,
    required this.contentRatingConfirmed,
    required this.appIconUrl,
    required this.screenshotsUrls,
    required this.adminNotes,
    required this.publisherProfile,
  });

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static List<String> _parseShots(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();

    // backend gives screenshotsUrlsJson as JSON string
    final s = v.toString();
    if (s.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  factory AppPublishRequestAdminModel.fromJson(Map<String, dynamic> j) {
    return AppPublishRequestAdminModel(
      id: (j['id'] as num).toInt(),
      aupId: j['aupId'] == null ? null : (j['aupId'] as num).toInt(),
      appName: j['appName']?.toString(),
      platform: (j['platform'] ?? '').toString(),
      store: (j['store'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      requestedAt: _dt(j['requestedAt']),
      reviewedAt: _dt(j['reviewedAt']),
      packageNameSnapshot: j['packageNameSnapshot']?.toString(),
      bundleIdSnapshot: j['bundleIdSnapshot']?.toString(),
      shortDescription: (j['shortDescription'] ?? '').toString(),
      fullDescription: (j['fullDescription'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      pricing: (j['pricing'] ?? 'FREE').toString(),
      contentRatingConfirmed: (j['contentRatingConfirmed'] == true),
      appIconUrl: j['appIconUrl']?.toString(),
      screenshotsUrls: _parseShots(j['screenshotsUrlsJson']),
      adminNotes: j['adminNotes']?.toString(),
      publisherProfile: j['publisherProfile'] == null
          ? null
          : PublisherProfileModel.fromJson(
              Map<String, dynamic>.from(j['publisherProfile'] as Map),
            ),
    );
  }

  AppPublishRequestAdmin toEntity() => AppPublishRequestAdmin(
        id: id,
        aupId: aupId,
        appName: appName,
        platform: platform,
        store: store,
        status: status,
        requestedAt: requestedAt,
        reviewedAt: reviewedAt,
        packageNameSnapshot: packageNameSnapshot,
        bundleIdSnapshot: bundleIdSnapshot,
        shortDescription: shortDescription,
        fullDescription: fullDescription,
        category: category,
        pricing: pricing,
        contentRatingConfirmed: contentRatingConfirmed,
        appIconUrl: appIconUrl,
        screenshotsUrls: screenshotsUrls,
        adminNotes: adminNotes,
        publisherProfile: publisherProfile == null
            ? null
            : PublisherProfile(
                id: publisherProfile!.id,
                store: publisherProfile!.store,
                developerName: publisherProfile!.developerName,
                developerEmail: publisherProfile!.developerEmail,
                privacyPolicyUrl: publisherProfile!.privacyPolicyUrl,
              ),
      );
}
