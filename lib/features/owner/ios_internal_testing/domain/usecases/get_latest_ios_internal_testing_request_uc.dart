import '../entities/ios_internal_testing_request.dart';
import '../repository/i_owner_ios_internal_testing_repository.dart';

class GetLatestIosInternalTestingRequestUc {
  final IOwnerIosInternalTestingRepository repo;

  const GetLatestIosInternalTestingRequestUc(this.repo);

  Future<IosInternalTestingRequest?> call({
    required int linkId,
  }) {
    return repo.getLatestRequest(linkId: linkId);
  }
}