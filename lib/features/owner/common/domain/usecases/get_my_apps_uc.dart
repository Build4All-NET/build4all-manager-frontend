import '../entities/owner_project.dart';
import '../repositories/i_owner_repository.dart';

class GetMyAppsUc {
  final IOwnerRepository repo;
  GetMyAppsUc(this.repo);

  Future<List<OwnerProject>> call() => repo.getMyApps();
}