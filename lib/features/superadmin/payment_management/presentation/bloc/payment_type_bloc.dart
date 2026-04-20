import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_payment_type.dart';
import '../../domain/usecases/get_payment_types.dart';
import '../../domain/usecases/toggle_payment_type.dart';
import '../../domain/usecases/update_payment_type.dart';
import 'payment_type_event.dart';
import 'payment_type_state.dart';

class PaymentTypeBloc extends Bloc<PaymentTypeEvent, PaymentTypeState> {
  final GetPaymentTypes getPaymentTypes;
  final CreatePaymentType createPaymentType;
  final UpdatePaymentType updatePaymentType;
  final TogglePaymentType togglePaymentType;

  PaymentTypeBloc({
    required this.getPaymentTypes,
    required this.createPaymentType,
    required this.updatePaymentType,
    required this.togglePaymentType,
  }) : super(const PaymentTypeState()) {
    on<LoadPaymentTypes>(_load);
    on<RefreshPaymentTypes>(_load);
    on<AddPaymentType>(_add);
    on<EditPaymentType>(_edit);
    on<TogglePaymentTypeActive>(_toggle);
  }

  Future<void> _load(
    PaymentTypeEvent _,
    Emitter<PaymentTypeState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final items = await getPaymentTypes();
      emit(state.copyWith(loading: false, items: items));
    } catch (err) {
      emit(state.copyWith(loading: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _add(
    AddPaymentType event,
    Emitter<PaymentTypeState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await createPaymentType(event.type);
      final items = await getPaymentTypes();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Payment type added successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(
          saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _edit(
    EditPaymentType event,
    Emitter<PaymentTypeState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await updatePaymentType(event.type);
      final items = await getPaymentTypes();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Payment type updated successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(
          saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _toggle(
    TogglePaymentTypeActive event,
    Emitter<PaymentTypeState> emit,
  ) async {
    final toggling = {...state.togglingIds, event.id};
    emit(state.copyWith(togglingIds: toggling, error: null, success: null));
    try {
      await togglePaymentType(id: event.id, isActive: event.isActive);
      final items = await getPaymentTypes();
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
        togglingIds: done,
        items: items,
        success: event.isActive ? 'Payment type activated.' : 'Payment type deactivated.',
      ));
    } catch (err) {
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
          togglingIds: done, error: ApiErrorHandler.message(err)));
    }
  }
}
