import '../entities/app_config.dart';
import '../entities/app_request.dart';
import '../entities/owner_project.dart';

abstract class IOwnerRepository {
  Future<AppConfig> getAppConfig();
  Future<List<AppRequest>> getMyRequests({required int ownerId});
  Future<List<OwnerProject>> getMyApps({required int ownerId});
  Future<List<AppRequest>> getRecentRequests(int ownerId, {int limit = 5});
 
  Future<void> rebuildAndroid({required int linkId});
  Future<void> rebuildIos({required int linkId});
  Future<void> deleteApp({required int linkId});
}
