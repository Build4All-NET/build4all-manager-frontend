import 'package:equatable/equatable.dart';
import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/app_request.dart';

class OwnerHomeState extends Equatable {
  final bool loading;
  final List<AppRequest> recent;
  final AppConfig? config;
  final String? error;

  /// ✅ Default empty => all inactive until API decides.
  final Set<String> availableKinds;

  const OwnerHomeState({
    this.loading = false,
    this.recent = const [],
    this.config,
    this.error,
    this.availableKinds = const {},
  });

  OwnerHomeState copyWith({
    bool? loading,
    List<AppRequest>? recent,
    AppConfig? config,
    String? error,
    Set<String>? availableKinds,
  }) {
    return OwnerHomeState(
      loading: loading ?? this.loading,
      recent: recent ?? this.recent,
      config: config ?? this.config,
      error: error,
      availableKinds: availableKinds ?? this.availableKinds,
    );
  }

  @override
  List<Object?> get props => [loading, recent, config, error, availableKinds];
}
