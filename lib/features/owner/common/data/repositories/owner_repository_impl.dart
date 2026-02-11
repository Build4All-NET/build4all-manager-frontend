import '../../domain/repositories/i_owner_repository.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_request.dart';
import '../../domain/entities/owner_project.dart';
import '../models/app_config_dto.dart';
import '../models/app_request_dto.dart';
import '../models/owner_project_dto.dart';
import '../services/owner_api.dart';

class OwnerRepositoryImpl implements IOwnerRepository {
  final OwnerApi api;
  OwnerRepositoryImpl(this.api);

  @override
  Future<AppConfig> getAppConfig() async {
    final AppConfigDto dto = await api.getAppConfig(); // safe fallback inside
    return dto.toEntity();
  }

  @override
  Future<List<AppRequest>> getMyRequests({required int ownerId}) async {
    final List<AppRequestDto> list = await api.getMyRequests(ownerId: ownerId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<OwnerProject>> getMyApps({required int ownerId}) async {
    final List<OwnerProjectDto> list = await api.getMyApps(ownerId: ownerId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<AppRequest>> getRecentRequests(int ownerId,
      {int limit = 5}) async {
    final all = await getMyRequests(ownerId: ownerId);
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList();
  }

   // ANDROID rebuild
  @override
  Future<void> rebuildAndroid({required int linkId}) {
    return api.rebuildAndroid(linkId: linkId);
  }

// IOS rebuild
  @override
  Future<void> rebuildIos({required int linkId}) {
    return api.rebuildIos(linkId: linkId);
  }


}
