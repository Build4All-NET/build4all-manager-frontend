import 'package:equatable/equatable.dart';

import '../../domain/entities/managed_payment_type.dart';

const _omit = Object();

class PaymentTypeState extends Equatable {
  final bool loading;
  final bool saving;
  final List<ManagedPaymentType> items;
  final String? error;
  final String? success;
  final Set<int> togglingIds;

  const PaymentTypeState({
    this.loading = false,
    this.saving = false,
    this.items = const [],
    this.error,
    this.success,
    this.togglingIds = const {},
  });

  PaymentTypeState copyWith({
    bool? loading,
    bool? saving,
    List<ManagedPaymentType>? items,
    Object? error = _omit,
    Object? success = _omit,
    Set<int>? togglingIds,
  }) =>
      PaymentTypeState(
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
