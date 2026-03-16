import '../entities/ios_internal_testing_app_summary.dart';
import '../repository/i_owner_ios_internal_testing_repository.dart';

class GetIosInternalTestingAppSummaryUc {
  final IOwnerIosInternalTestingRepository repo;

  const GetIosInternalTestingAppSummaryUc(this.repo);

  Future<IosInternalTestingAppSummary> call({
    required int linkId,
  }) {
    return repo.getRequestsSummaryForApp(linkId: linkId);
  }
}