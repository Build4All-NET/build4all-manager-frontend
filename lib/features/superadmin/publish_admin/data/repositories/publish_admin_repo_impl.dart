import 'package:build4all_manager/features/superadmin/publish_admin/data/services/publish_admin_remote_ds.dart';

import '../../domain/entities/app_publish_request_admin.dart';
import '../../domain/entities/publisher_profile.dart';
import '../../domain/repositories/publish_admin_repo.dart';


class PublishAdminRepoImpl implements PublishAdminRepo {
  final PublishAdminRemoteDs remote;
  PublishAdminRepoImpl(this.remote);

  @override
  Future<List<AppPublishRequestAdmin>> getRequests(
      {required String status}) async {
    final models = await remote.getRequests(status);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> approve({required int requestId, String? notes}) {
    return remote.approve(requestId, notes);
  }

  @override
  Future<void> reject({required int requestId, String? notes}) {
    return remote.reject(requestId, notes);
  }

  @override
  Future<List<PublisherProfile>> getPublisherProfiles() async {
    final models = await remote.getProfiles();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PublisherProfile> upsertPublisherProfile({
    required String store,
    required String developerName,
    required String developerEmail,
    required String privacyPolicyUrl,
  }) async {
    final m = await remote.upsertProfile(
      store: store,
      developerName: developerName,
      developerEmail: developerEmail,
      privacyPolicyUrl: privacyPolicyUrl,
    );
    return m.toEntity();
  }
}
