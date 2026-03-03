import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/owner_project.dart';

class OwnerHomeState extends Equatable {
  final bool loading;
  final AppConfig? config;
  final String? error;

  // ✅ list of apps from /owner/my-apps
  final List<OwnerProject> myApps;

  /// ✅ Available kinds from ACTIVE apps only
  final Set<String> availableKinds;

  /// ✅ kind -> real DB projectId
  final Map<String, int> kindToProjectId;

  const OwnerHomeState({
    this.loading = false,
    this.config,
    this.error,
    this.myApps = const [],
    this.availableKinds = const {},
    this.kindToProjectId = const {},
  });

  OwnerHomeState copyWith({
    bool? loading,
    AppConfig? config,
    String? error,
    List<OwnerProject>? myApps,
    Set<String>? availableKinds,
    Map<String, int>? kindToProjectId,
  }) {
    return OwnerHomeState(
      loading: loading ?? this.loading,
      config: config ?? this.config,
      error: error,
      myApps: myApps ?? this.myApps,
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
        availableKinds,
        kindToProjectId,
      ];
}