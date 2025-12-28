// lib/features/owner/ownerhome/presentation/bloc/owner_home_state.dart
import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/app_request.dart';

class OwnerHomeState extends Equatable {
  final bool loading;
  final List<AppRequest> recent;
  final AppConfig? config;
  final String? error;

  /// ✅ Available kinds from active DB projects only
  /// empty => all disabled
  final Set<String> availableKinds;

  /// ✅ kind -> real DB projectId
  /// empty => none available
  final Map<String, int> kindToProjectId;

  const OwnerHomeState({
    this.loading = false,
    this.recent = const [],
    this.config,
    this.error,
    this.availableKinds = const {},
    this.kindToProjectId = const {},
  });

  OwnerHomeState copyWith({
    bool? loading,
    List<AppRequest>? recent,
    AppConfig? config,
    String? error,
    Set<String>? availableKinds,
    Map<String, int>? kindToProjectId,
  }) {
    return OwnerHomeState(
      loading: loading ?? this.loading,
      recent: recent ?? this.recent,
      config: config ?? this.config,
      error: error,
      availableKinds: availableKinds ?? this.availableKinds,
      kindToProjectId: kindToProjectId ?? this.kindToProjectId,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        recent,
        config,
        error,
        availableKinds,
        kindToProjectId,
      ];
}
