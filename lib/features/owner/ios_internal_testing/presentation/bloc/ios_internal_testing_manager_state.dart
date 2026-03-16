import 'package:equatable/equatable.dart';

import '../../domain/entities/ios_internal_testing_app_summary.dart';
import '../../domain/entities/ios_internal_testing_request.dart';

class IosInternalTestingManagerState extends Equatable {
  final bool loading;
  final bool submitting;
  final IosInternalTestingAppSummary? summary;
  final String? error;
  final String? message;

  const IosInternalTestingManagerState({
    this.loading = false,
    this.submitting = false,
    this.summary,
    this.error,
    this.message,
  });

  List<IosInternalTestingRequest> get requests => summary?.requests ?? const [];

  int get usedSlots => summary?.usedSlots ?? 0;

  int get maxSlots => summary?.maxSlots ?? 0;

  int get remainingSlots => summary?.remainingSlots ?? 0;

  bool get isFull => summary?.isFull ?? false;

  bool get hasRequests => requests.isNotEmpty;

  IosInternalTestingManagerState copyWith({
    bool? loading,
    bool? submitting,
    IosInternalTestingAppSummary? summary,
    bool keepSummary = true,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) {
    return IosInternalTestingManagerState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      summary: keepSummary ? (summary ?? this.summary) : summary,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        loading,
        submitting,
        summary?.usedSlots,
        summary?.maxSlots,
        summary?.requests.length,
        requests.map((e) => '${e.id}-${e.status}-${e.updatedAt}').join('|'),
        error,
        message,
      ];
}