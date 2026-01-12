import '../entities/app_publish_request_admin.dart';
import '../entities/publisher_profile.dart';

abstract class PublishAdminRepo {
  Future<List<AppPublishRequestAdmin>> getRequests({required String status});
  Future<void> approve({required int requestId, String? notes});
  Future<void> reject({required int requestId, String? notes});

  Future<List<PublisherProfile>> getPublisherProfiles();
  Future<PublisherProfile> upsertPublisherProfile({
    required String store,
    required String developerName,
    required String developerEmail,
    required String privacyPolicyUrl,
  });
}
