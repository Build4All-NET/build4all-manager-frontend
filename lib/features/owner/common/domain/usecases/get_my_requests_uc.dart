import '../entities/app_request.dart';
import '../repositories/i_owner_repository.dart';

class GetMyRequestsUc {
  final IOwnerRepository repo;
  GetMyRequestsUc(this.repo);

  Future<List<AppRequest>> call() => repo.getMyRequests();
}