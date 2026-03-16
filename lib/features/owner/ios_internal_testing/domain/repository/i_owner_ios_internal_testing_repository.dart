import '../entities/ios_internal_testing_app_summary.dart';
import '../entities/ios_internal_testing_request.dart';

abstract class IOwnerIosInternalTestingRepository {
  Future<IosInternalTestingRequest> createRequest({
    required int linkId,
    required String appleEmail,
    required String firstName,
    required String lastName,
  });

  Future<IosInternalTestingRequest?> getLatestRequest({
    required int linkId,
  });

  Future<IosInternalTestingAppSummary> getRequestsSummaryForApp({
    required int linkId,
  });
}