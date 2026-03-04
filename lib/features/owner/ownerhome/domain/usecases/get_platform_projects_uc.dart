import '../../data/models/backend_project_dto.dart';
import '../../domain/entities/backend_project.dart';
import '../../domain/repositories/i_owner_projects_repository.dart';

class GetPlatformProjectsUc {
  final IOwnerProjectsRepository repo;
  const GetPlatformProjectsUc(this.repo);

  Future<List<BackendProject>> call() => repo.getProjects();
}