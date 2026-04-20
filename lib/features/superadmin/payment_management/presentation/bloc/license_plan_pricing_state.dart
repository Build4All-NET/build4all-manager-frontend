import 'package:equatable/equatable.dart';

import '../../domain/entities/license_plan_pricing.dart';

const _omit = Object();

class LicensePlanPricingState extends Equatable {
  final bool loading;
  final bool saving;
  final List<LicensePlanPricing> items;
  final String? error;
  final String? success;
  final Set<int> togglingIds;

  const LicensePlanPricingState({
    this.loading = false,
    this.saving = false,
    this.items = const [],
    this.error,
    this.success,
    this.togglingIds = const {},
  });

  LicensePlanPricingState copyWith({
    bool? loading,
    bool? saving,
    List<LicensePlanPricing>? items,
    Object? error = _omit,
    Object? success = _omit,
    Set<int>? togglingIds,
  }) =>
      LicensePlanPricingState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        items: items ?? this.items,
        error: identical(error, _omit) ? this.error : error as String?,
        success: identical(success, _omit) ? this.success : success as String?,
        togglingIds: togglingIds ?? this.togglingIds,
      );

  @override
  List<Object?> get props =>
      [loading, saving, items, error, success, togglingIds];
}
