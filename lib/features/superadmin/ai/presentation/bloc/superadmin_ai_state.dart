import '../../domain/entities/owner_ai_status.dart';

class SuperAdminAiState {
  final bool loading;
  final bool updating;
  final String? error;
  final OwnerAiStatus? status;

  const SuperAdminAiState({
    required this.loading,
    required this.updating,
    this.error,
    this.status,
  });

  factory SuperAdminAiState.initial() => const SuperAdminAiState(
        loading: true,
        updating: false,
        error: null,
        status: null,
      );

  SuperAdminAiState copyWith({
    bool? loading,
    bool? updating,
    String? error,
    OwnerAiStatus? status,
    bool clearError = false,
  }) {
    return SuperAdminAiState(
      loading: loading ?? this.loading,
      updating: updating ?? this.updating,
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
    );
  }
}
