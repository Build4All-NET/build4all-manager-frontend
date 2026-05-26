import '../repositories/publish_admin_repo.dart';

class ApproveRequest {
  final PublishAdminRepo repo;
  const ApproveRequest(this.repo);

  Future<void> call({
    required int requestId,
    String? notes,
    int? firebaseProjectAccountId,
  }) {
    return repo.approve(
      requestId: requestId,
      notes: notes,
      firebaseProjectAccountId: firebaseProjectAccountId,
    );
  }
}
