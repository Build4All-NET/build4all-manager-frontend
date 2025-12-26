import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/theme_lite.dart';
import '../../../common/domain/entities/app_request.dart';

class OwnerRequestsState extends Equatable {
  final bool loading;
  final bool submitting;
  final bool uploadingLogo;
  final bool building;
  final String? error;

  final List<Project> projects;
  final List<AppRequest> myRequests;

  final List<ThemeLite> themes;
  final int? selectedThemeId;

  final String? logoUrl;
  final String? logoFilePath;

  final Project? selected;
  final String appName;

  // ✅ NEW runtime-config fields
  final int? currencyId;
  final String? apiBaseUrlOverride;

  final String? navJson;
  final String? homeJson;
  final String? enabledFeaturesJson;
  final String? brandingJson;

  final AppRequest? lastCreated;
  final String? builtApkUrl;
  final String? builtAt;

  const OwnerRequestsState({
    required this.loading,
    required this.submitting,
    required this.uploadingLogo,
    required this.building,
    required this.error,
    required this.projects,
    required this.myRequests,
    required this.themes,
    required this.selectedThemeId,
    required this.logoUrl,
    required this.logoFilePath,
    required this.selected,
    required this.appName,
    required this.currencyId,
    required this.apiBaseUrlOverride,
    required this.navJson,
    required this.homeJson,
    required this.enabledFeaturesJson,
    required this.brandingJson,
    required this.lastCreated,
    required this.builtApkUrl,
    required this.builtAt,
  });

  const OwnerRequestsState.initial()
      : loading = false,
        submitting = false,
        uploadingLogo = false,
        building = false,
        error = null,
        projects = const [],
        myRequests = const [],
        themes = const [],
        selectedThemeId = null,
        logoUrl = null,
        logoFilePath = null,
        selected = null,
        appName = '',
        currencyId = null,
        apiBaseUrlOverride = null,
        navJson = null,
        homeJson = null,
        enabledFeaturesJson = null,
        brandingJson = null,
        lastCreated = null,
        builtApkUrl = null,
        builtAt = null;

  OwnerRequestsState copyWith({
    bool? loading,
    bool? submitting,
    bool? uploadingLogo,
    bool? building,
    String? error,
    List<Project>? projects,
    List<AppRequest>? myRequests,
    List<ThemeLite>? themes,
    int? selectedThemeId,
    String? logoUrl,
    String? logoFilePath,
    Project? selected,
    String? appName,
    int? currencyId,
    String? apiBaseUrlOverride,
    String? navJson,
    String? homeJson,
    String? enabledFeaturesJson,
    String? brandingJson,
    AppRequest? lastCreated,
    String? builtApkUrl,
    String? builtAt,
  }) {
    return OwnerRequestsState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      uploadingLogo: uploadingLogo ?? this.uploadingLogo,
      building: building ?? this.building,
      error: error,
      projects: projects ?? this.projects,
      myRequests: myRequests ?? this.myRequests,
      themes: themes ?? this.themes,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      logoUrl: logoUrl ?? this.logoUrl,
      logoFilePath: logoFilePath ?? this.logoFilePath,
      selected: selected ?? this.selected,
      appName: appName ?? this.appName,
      currencyId: currencyId ?? this.currencyId,
      apiBaseUrlOverride: apiBaseUrlOverride ?? this.apiBaseUrlOverride,
      navJson: navJson ?? this.navJson,
      homeJson: homeJson ?? this.homeJson,
      enabledFeaturesJson: enabledFeaturesJson ?? this.enabledFeaturesJson,
      brandingJson: brandingJson ?? this.brandingJson,
      lastCreated: lastCreated ?? this.lastCreated,
      builtApkUrl: builtApkUrl ?? this.builtApkUrl,
      builtAt: builtAt ?? this.builtAt,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        submitting,
        uploadingLogo,
        building,
        error,
        projects,
        myRequests,
        themes,
        selectedThemeId,
        logoUrl,
        logoFilePath,
        selected,
        appName,
        currencyId,
        apiBaseUrlOverride,
        navJson,
        homeJson,
        enabledFeaturesJson,
        brandingJson,
        lastCreated,
        builtApkUrl,
        builtAt,
      ];
}
