import '../entities/app_publish_request_admin.dart';
import '../repositories/publish_admin_repo.dart';

class GetPublishRequests {
  final PublishAdminRepo repo;
  const GetPublishRequests(this.repo);

  Future<List<AppPublishRequestAdmin>> call({required String status}) {
    return repo.getRequests(status: status);
  }
}
