import 'package:equatable/equatable.dart';

enum SprintReleaseStatus { idle, loading, success, failure }

class SprintReleaseState extends Equatable {
  final SprintReleaseStatus status;
  final String? savedPat;
  final String? error;

  const SprintReleaseState({
    this.status = SprintReleaseStatus.idle,
    this.savedPat,
    this.error,
  });

  SprintReleaseState copyWith({
    SprintReleaseStatus? status,
    String? savedPat,
    bool clearPat = false,
    String? error,
    bool clearError = false,
  }) {
    return SprintReleaseState(
      status: status ?? this.status,
      savedPat: clearPat ? null : (savedPat ?? this.savedPat),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, savedPat, error];
}
