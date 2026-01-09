import 'dart:convert';

enum PublishPlatform { android, ios }

enum PublishStore { playStore, appStore }

enum PublishStatus { draft, submitted, approved, rejected }

enum PricingType { free, paid }

PublishPlatform platformFromApi(String v) =>
    v.toUpperCase() == 'IOS' ? PublishPlatform.ios : PublishPlatform.android;

PublishStore storeFromApi(String v) => v.toUpperCase().contains('APP')
    ? PublishStore.appStore
    : PublishStore.playStore;

PublishStatus statusFromApi(String v) {
  final u = v.toUpperCase();
  if (u == 'SUBMITTED') return PublishStatus.submitted;
  if (u == 'APPROVED') return PublishStatus.approved;
  if (u == 'REJECTED') return PublishStatus.rejected;
  return PublishStatus.draft;
}

PricingType pricingFromApi(String? v) =>
    (v ?? '').toUpperCase() == 'PAID' ? PricingType.paid : PricingType.free;

String platformToApi(PublishPlatform p) =>
    p == PublishPlatform.ios ? 'IOS' : 'ANDROID';
String storeToApi(PublishStore s) =>
    s == PublishStore.appStore ? 'APP_STORE' : 'PLAY_STORE';
String pricingToApi(PricingType p) => p == PricingType.paid ? 'PAID' : 'FREE';

class PublishDraft {
  final int id;
  final int aupId;
  final PublishPlatform platform;
  final PublishStore store;
  final PublishStatus status;

  final String applicationName;
  final String packageNameSnapshot;
  final String bundleIdSnapshot;

  final String shortDescription;
  final String fullDescription;

  final String category;
  final String countryAvailability;

  final PricingType pricing;
  final bool contentRatingConfirmed;

  final String appIconUrl;
  final List<String> screenshotsUrls;

  final String adminNotes;

  const PublishDraft({
    required this.id,
    required this.aupId,
    required this.platform,
    required this.store,
    required this.status,
    required this.applicationName,
    required this.packageNameSnapshot,
    required this.bundleIdSnapshot,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.countryAvailability,
    required this.pricing,
    required this.contentRatingConfirmed,
    required this.appIconUrl,
    required this.screenshotsUrls,
    required this.adminNotes,
  });

  factory PublishDraft.fromJson(Map<String, dynamic> j) {
    final rawShots = (j['screenshotsUrlsJson'] ?? '').toString();
    List<String> shots = [];
    try {
      final decoded = jsonDecode(rawShots);
      if (decoded is List) {
        shots = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return PublishDraft(
      id: (j['id'] ?? 0) as int,
      aupId: (j['aupId'] ?? 0) as int,
      platform: platformFromApi((j['platform'] ?? 'ANDROID').toString()),
      store: storeFromApi((j['store'] ?? 'GOOGLE_PLAY').toString()),
      status: statusFromApi((j['status'] ?? 'DRAFT').toString()),
      applicationName: (j['applicationName'] ?? '').toString(),
      packageNameSnapshot: (j['packageNameSnapshot'] ?? '').toString(),
      bundleIdSnapshot: (j['bundleIdSnapshot'] ?? '').toString(),
      shortDescription: (j['shortDescription'] ?? '').toString(),
      fullDescription: (j['fullDescription'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      countryAvailability: (j['countryAvailability'] ?? '').toString(),
      pricing: pricingFromApi(j['pricing']?.toString()),
      contentRatingConfirmed: (j['contentRatingConfirmed'] ?? false) as bool,
      appIconUrl: (j['appIconUrl'] ?? '').toString(),
      screenshotsUrls: shots,
      adminNotes: (j['adminNotes'] ?? '').toString(),
    );
  }

  PublishDraft copyWith({
    String? applicationName,
    String? shortDescription,
    String? fullDescription,
    String? category,
    String? countryAvailability,
    PricingType? pricing,
    bool? contentRatingConfirmed,
    String? appIconUrl,
    List<String>? screenshotsUrls,
  }) {
    return PublishDraft(
      id: id,
      aupId: aupId,
      platform: platform,
      store: store,
      status: status,
      applicationName: applicationName ?? this.applicationName,
      packageNameSnapshot: packageNameSnapshot,
      bundleIdSnapshot: bundleIdSnapshot,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      category: category ?? this.category,
      countryAvailability: countryAvailability ?? this.countryAvailability,
      pricing: pricing ?? this.pricing,
      contentRatingConfirmed:
          contentRatingConfirmed ?? this.contentRatingConfirmed,
      appIconUrl: appIconUrl ?? this.appIconUrl,
      screenshotsUrls: screenshotsUrls ?? this.screenshotsUrls,
      adminNotes: adminNotes,
    );
  }
}
