import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_method.dart';

const _omit = Object();

class PaymentMethodState extends Equatable {
  final bool loading;
  final List<PaymentMethod> items;
  final String? error;
  final String? success;
  final bool saving;
  final Set<int> togglingIds;

  const PaymentMethodState({
    this.loading = false,
    this.items = const [],
    this.error,
    this.success,
    this.saving = false,
    this.togglingIds = const {},
  });

  PaymentMethodState copyWith({
    bool? loading,
    List<PaymentMethod>? items,
    Object? error = _omit,
    Object? success = _omit,
    bool? saving,
    Set<int>? togglingIds,
  }) =>
      PaymentMethodState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        error: identical(error, _omit) ? this.error : error as String?,
        success:
            identical(success, _omit) ? this.success : success as String?,
        saving: saving ?? this.saving,
        togglingIds: togglingIds ?? this.togglingIds,
      );

  @override
  List<Object?> get props =>
      [loading, items, error, success, saving, togglingIds];
}
