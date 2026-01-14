import 'publisher_profile.dart';

class AppPublishRequestAdmin {
  final int id;

  final int? aupId;
  final String? appName;

  final String platform; // ANDROID / IOS
  final String store; // PLAY_STORE / APP_STORE
  final String status; // DRAFT / SUBMITTED / APPROVED ...

  final DateTime? requestedAt;
  final DateTime? reviewedAt;

  final String? packageNameSnapshot;
  final String? bundleIdSnapshot;

  final String shortDescription;
  final String fullDescription;
  final String category;

  final String pricing; // FREE / PAID
  final bool contentRatingConfirmed;

  final String? appIconUrl;
  final List<String> screenshotsUrls;

  final String? adminNotes;

  final PublisherProfile? publisherProfile;
  final int? androidVersionCode;
  final String? androidVersionName;
  final int? iosBuildNumber;
  final String? iosVersionName;

  final String? apkUrl;
  final String? bundleUrl; // AAB
  final String? ipaUrl;
  final String? logoUrl;


  const AppPublishRequestAdmin({
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
    this.androidVersionCode,
    this.androidVersionName,
    this.iosBuildNumber,
    this.iosVersionName,
    this.apkUrl,
    this.bundleUrl,
    this.ipaUrl,
    this.logoUrl,
  });

  bool get isSubmitted => status.toUpperCase() == 'SUBMITTED';
}
