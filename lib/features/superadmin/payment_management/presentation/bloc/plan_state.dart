import 'package:equatable/equatable.dart';

import '../../domain/entities/plan.dart';

const _omit = Object();

class PlanState extends Equatable {
  final bool loading;
  final bool saving;
  final List<Plan> items;
  final String? error;
  final String? success;
  final Set<String> deletingCodes;

  const PlanState({
    this.loading = false,
    this.saving = false,
    this.items = const [],
    this.error,
    this.success,
    this.deletingCodes = const {},
  });

  PlanState copyWith({
    bool? loading,
    bool? saving,
    List<Plan>? items,
    Object? error = _omit,
    Object? success = _omit,
    Set<String>? deletingCodes,
  }) =>
      PlanState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        items: items ?? this.items,
        error: identical(error, _omit) ? this.error : error as String?,
        success: identical(success, _omit) ? this.success : success as String?,
        deletingCodes: deletingCodes ?? this.deletingCodes,
      );

  @override
  List<Object?> get props =>
      [loading, saving, items, error, success, deletingCodes];
}
