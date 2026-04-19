import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_payment_method.dart';
import '../../domain/usecases/get_payment_methods.dart';
import '../../domain/usecases/toggle_payment_method.dart';
import '../../domain/usecases/update_payment_method.dart';
import 'payment_method_event.dart';
import 'payment_method_state.dart';

class PaymentMethodBloc
    extends Bloc<PaymentMethodEvent, PaymentMethodState> {
  final GetPaymentMethods getPaymentMethods;
  final CreatePaymentMethod createPaymentMethod;
  final UpdatePaymentMethod updatePaymentMethod;
  final TogglePaymentMethod togglePaymentMethod;

  PaymentMethodBloc({
    required this.getPaymentMethods,
    required this.createPaymentMethod,
    required this.updatePaymentMethod,
    required this.togglePaymentMethod,
  }) : super(const PaymentMethodState()) {
    on<LoadPaymentMethods>(_load);
    on<RefreshPaymentMethods>(_load);
    on<AddPaymentMethod>(_add);
    on<EditPaymentMethod>(_edit);
    on<TogglePaymentMethodEnabled>(_toggle);
  }

  Future<void> _load(
    PaymentMethodEvent _,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final items = await getPaymentMethods();
      emit(state.copyWith(loading: false, items: items));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _add(
    AddPaymentMethod event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await createPaymentMethod(
        name: event.name,
        type: event.type,
        provider: event.provider,
      );
      final items = await getPaymentMethods();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Payment method added successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _edit(
    EditPaymentMethod event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await updatePaymentMethod(
        id: event.id,
        name: event.name,
        type: event.type,
        provider: event.provider,
      );
      final items = await getPaymentMethods();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Payment method updated successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _toggle(
    TogglePaymentMethodEnabled event,
    Emitter<PaymentMethodState> emit,
  ) async {
    final toggling = {...state.togglingIds, event.id};
    emit(state.copyWith(togglingIds: toggling, error: null, success: null));
    try {
      await togglePaymentMethod(id: event.id, enabled: event.enabled);
      final items = await getPaymentMethods();
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
        togglingIds: done,
        items: items,
        success: event.enabled
            ? 'Payment method enabled.'
            : 'Payment method disabled.',
      ));
    } catch (err) {
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
        togglingIds: done,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}
