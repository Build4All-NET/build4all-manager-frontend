import 'package:build4all_manager/features/owner/ios_internal_testing/domain/repository/i_owner_ios_internal_testing_repository.dart';

import '../../domain/entities/ios_internal_testing_app_summary.dart';
import '../../domain/entities/ios_internal_testing_request.dart';

import '../services/owner_ios_internal_testing_api.dart';

class OwnerIosInternalTestingRepositoryImpl
    implements IOwnerIosInternalTestingRepository {
  final OwnerIosInternalTestingApi api;

  OwnerIosInternalTestingRepositoryImpl(this.api);

  @override
  Future<IosInternalTestingRequest> createRequest({
    required int linkId,
    required String appleEmail,
    required String firstName,
    required String lastName,
  }) async {
    final dto = await api.createRequest(
      linkId: linkId,
      appleEmail: appleEmail,
      firstName: firstName,
      lastName: lastName,
    );
    return dto.toEntity();
  }

  @override
  Future<IosInternalTestingRequest?> getLatestRequest({
    required int linkId,
  }) async {
    final dto = await api.getLatestRequest(linkId: linkId);
    return dto?.toEntity();
  }

  @override
  Future<IosInternalTestingAppSummary> getRequestsSummaryForApp({
    required int linkId,
  }) async {
    final dto = await api.getRequestsSummaryForApp(linkId: linkId);
    return dto.toEntity();
  }
}