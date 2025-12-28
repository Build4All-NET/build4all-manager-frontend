import 'package:equatable/equatable.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/theme_lite.dart';
import '../../../common/domain/entities/app_request.dart';

class OwnerRequestsState extends Equatable {
  final bool loading;
  final bool submitting;
  final String? error;

  final List<Project> projects;
  final List<AppRequest> myRequests;

  final List<ThemeLite> themes;
  final int? selectedThemeId;

  final Project? selectedProject;
  final String appName;
  final String? logoFilePath;

  // runtime config
  final int? currencyId;
  final String notes;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String onBackgroundColor;
  final String errorColor;

  final String navJson;
  final String homeJson;
  final String enabledFeaturesJson;
  final String brandingJson;
  final String? apiBaseUrlOverride;

  final AppRequest? lastCreated;

  const OwnerRequestsState({
    required this.loading,
    required this.submitting,
    required this.error,
    required this.projects,
    required this.myRequests,
    required this.themes,
    required this.selectedThemeId,
    required this.selectedProject,
    required this.appName,
    required this.logoFilePath,
    required this.currencyId,
    required this.notes,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.errorColor,
    required this.navJson,
    required this.homeJson,
    required this.enabledFeaturesJson,
    required this.brandingJson,
    required this.apiBaseUrlOverride,
    required this.lastCreated,
  });

  const OwnerRequestsState.initial()
      : loading = false,
        submitting = false,
        error = null,
        projects = const [],
        myRequests = const [],
        themes = const [],
        selectedThemeId = null,
        selectedProject = null,
        appName = '',
        logoFilePath = null,
        currencyId = null,
        notes = '',
        primaryColor = '#EC4899',
        secondaryColor = '#111827',
        backgroundColor = '#FFFFFF',
        onBackgroundColor = '#374151',
        errorColor = '#DC2626',
        navJson = '[]',
        homeJson = '{"sections":[]}',
        enabledFeaturesJson = '[]',
        brandingJson = '{"splashColor":"#FFFFFF"}',
        apiBaseUrlOverride = null,
        lastCreated = null;

  OwnerRequestsState copyWith({
    bool? loading,
    bool? submitting,
    String? error,
    List<Project>? projects,
    List<AppRequest>? myRequests,
    List<ThemeLite>? themes,
    int? selectedThemeId,
    Project? selectedProject,
    String? appName,
    String? logoFilePath,
    int? currencyId,
    String? notes,
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? onBackgroundColor,
    String? errorColor,
    String? navJson,
    String? homeJson,
    String? enabledFeaturesJson,
    String? brandingJson,
    String? apiBaseUrlOverride,
    AppRequest? lastCreated,
  }) {
    return OwnerRequestsState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: error,
      projects: projects ?? this.projects,
      myRequests: myRequests ?? this.myRequests,
      themes: themes ?? this.themes,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      selectedProject: selectedProject ?? this.selectedProject,
      appName: appName ?? this.appName,
      logoFilePath: logoFilePath ?? this.logoFilePath,
      currencyId: currencyId ?? this.currencyId,
      notes: notes ?? this.notes,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      onBackgroundColor: onBackgroundColor ?? this.onBackgroundColor,
      errorColor: errorColor ?? this.errorColor,
      navJson: navJson ?? this.navJson,
      homeJson: homeJson ?? this.homeJson,
      enabledFeaturesJson: enabledFeaturesJson ?? this.enabledFeaturesJson,
      brandingJson: brandingJson ?? this.brandingJson,
      apiBaseUrlOverride: apiBaseUrlOverride ?? this.apiBaseUrlOverride,
      lastCreated: lastCreated ?? this.lastCreated,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        submitting,
        error,
        projects,
        myRequests,
        themes,
        selectedThemeId,
        selectedProject,
        appName,
        logoFilePath,
        currencyId,
        notes,
        primaryColor,
        secondaryColor,
        backgroundColor,
        onBackgroundColor,
        errorColor,
        navJson,
        homeJson,
        enabledFeaturesJson,
        brandingJson,
        apiBaseUrlOverride,
        lastCreated,
      ];
}
