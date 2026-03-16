import '../entities/ios_internal_testing_request.dart';
import '../repository/i_owner_ios_internal_testing_repository.dart';

class CreateIosInternalTestingRequestUc {
  final IOwnerIosInternalTestingRepository repo;

  const CreateIosInternalTestingRequestUc(this.repo);

  Future<IosInternalTestingRequest> call({
    required int linkId,
    required String appleEmail,
    required String firstName,
    required String lastName,
  }) {
    return repo.createRequest(
      linkId: linkId,
      appleEmail: appleEmail,
      firstName: firstName,
      lastName: lastName,
    );
  }
}