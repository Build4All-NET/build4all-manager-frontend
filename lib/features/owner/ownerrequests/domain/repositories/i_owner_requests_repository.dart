import '../../domain/entities/project.dart';
import '../../../common/domain/entities/app_request.dart';
import '../../domain/entities/theme_lite.dart';

abstract class IOwnerRequestsRepository {
  Future<List<Project>> getAvailableProjects();
  Future<List<AppRequest>> getMyRequests(int ownerId);
  Future<List<ThemeLite>> getThemes();

  Future<AppRequest> createAppRequestManual({
    required int ownerId,
    required int projectId,
    required String appName,
    required int currencyId,
    required String notes,
    required String primaryColor,
    required String secondaryColor,
    required String backgroundColor,
    required String onBackgroundColor,
    required String errorColor,
    required String navJson,
    required String homeJson,
    required String enabledFeaturesJson,
    required String brandingJson,
    String? apiBaseUrlOverride,
    int? themeId,
    String? slug,
    String? logoFilePath,
  });
}
