import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/owner_project.dart';
import '../../domain/entities/backend_project.dart';

class OwnerHomeState extends Equatable {
  final bool loading;
  final AppConfig? config;
  final String? error;

  final List<OwnerProject> myApps;

  // ✅ NEW: platform projects from /api/projects
  final List<BackendProject> platformProjects;

  final Set<String> availableKinds;
  final Map<String, int> kindToProjectId;

  const OwnerHomeState({
    this.loading = false,
    this.config,
    this.error,
    this.myApps = const [],
    this.platformProjects = const [],
    this.availableKinds = const {},
    this.kindToProjectId = const {},
  });

  OwnerHomeState copyWith({
    bool? loading,
    AppConfig? config,
    String? error,
    List<OwnerProject>? myApps,
    List<BackendProject>? platformProjects,
    Set<String>? availableKinds,
    Map<String, int>? kindToProjectId,
  }) {
    return OwnerHomeState(
      loading: loading ?? this.loading,
      config: config ?? this.config,
      error: error,
      myApps: myApps ?? this.myApps,
      platformProjects: platformProjects ?? this.platformProjects,
      availableKinds: availableKinds ?? this.availableKinds,
      kindToProjectId: kindToProjectId ?? this.kindToProjectId,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        config,
        error,
        myApps,
        platformProjects,
        availableKinds,
        kindToProjectId,
      ];
}