import 'package:build4all_manager/features/owner/common/domain/entities/app_request.dart';
import 'package:build4all_manager/features/owner/ownerrequests/domain/entities/project.dart';
import 'package:build4all_manager/features/owner/ownerrequests/domain/entities/theme_lite.dart';

abstract class IOwnerRequestsRepository {
  Future<List<Project>> getAvailableProjects();
  Future<List<AppRequest>> getMyRequests(int ownerId);
  Future<List<ThemeLite>> getThemes();

  Future<AppRequest> createAppRequestAuto({
    required int ownerId,
    required int projectId,
    required String appName,
    int? themeId,
    String? logoUrl,
    String? slug,
    String? logoFilePath,
  });

  // ✅ NEW: manual request (palette + currency + raw json)
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
