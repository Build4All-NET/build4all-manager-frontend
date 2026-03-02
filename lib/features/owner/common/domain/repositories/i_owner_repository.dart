import '../entities/app_config.dart';
import '../entities/app_request.dart';
import '../entities/owner_project.dart';

abstract class IOwnerRepository {
  Future<AppConfig> getAppConfig();

  // ✅ no ownerId
  Future<List<AppRequest>> getMyRequests();
  Future<List<OwnerProject>> getMyApps();

  Future<List<AppRequest>> getRecentRequests({int limit = 5});

  Future<void> rebuildAndroid({required int linkId});
  Future<void> rebuildIos({required int linkId});
  Future<void> deleteApp({required int linkId});
}