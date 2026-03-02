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
    final dto = await api.getAppConfig();
    return dto.toEntity();
  }

  @override
  Future<List<AppRequest>> getMyRequests() async {
    final list = await api.getMyRequests();
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<OwnerProject>> getMyApps() async {
    final list = await api.getMyApps();
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<AppRequest>> getRecentRequests({int limit = 5}) async {
    return api.getRecentRequests(limit: limit);
  }

  @override
  Future<void> rebuildAndroid({required int linkId}) => api.rebuildAndroid(linkId: linkId);

  @override
  Future<void> rebuildIos({required int linkId}) => api.rebuildIos(linkId: linkId);

  @override
  Future<void> deleteApp({required int linkId}) => api.deleteApp(linkId: linkId);
}