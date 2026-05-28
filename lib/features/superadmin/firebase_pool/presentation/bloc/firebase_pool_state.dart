import '../../domain/entities/firebase_project_account.dart';

class FirebasePoolState {
  final bool loading;
  final List<FirebaseProjectAccount> items;
  final Set<int> actingIds;
  final String? error;
  final String? success;

  const FirebasePoolState({
    this.loading = false,
    this.items = const [],
    this.actingIds = const {},
    this.error,
    this.success,
  });

  FirebasePoolState copyWith({
    bool? loading,
    List<FirebaseProjectAccount>? items,
    Set<int>? actingIds,
    String? error,
    String? success,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return FirebasePoolState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      actingIds: actingIds ?? this.actingIds,
      error: clearError ? null : (error ?? this.error),
      success: clearSuccess ? null : (success ?? this.success),
    );
  }
}
