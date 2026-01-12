import '../repositories/publish_admin_repo.dart';

class RejectRequest {
  final PublishAdminRepo repo;
  const RejectRequest(this.repo);

  Future<void> call({required int requestId, String? notes}) {
    return repo.reject(requestId: requestId, notes: notes);
  }
}
