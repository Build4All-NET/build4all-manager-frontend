import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_license_plan_pricing.dart';
import '../../domain/usecases/get_license_plan_pricings.dart';
import '../../domain/usecases/toggle_license_plan_pricing.dart';
import '../../domain/usecases/update_license_plan_pricing.dart';
import 'license_plan_pricing_event.dart';
import 'license_plan_pricing_state.dart';

class LicensePlanPricingBloc
    extends Bloc<LicensePlanPricingEvent, LicensePlanPricingState> {
  final GetLicensePlanPricings getAll;
  final CreateLicensePlanPricing createOne;
  final UpdateLicensePlanPricing updateOne;
  final ToggleLicensePlanPricing toggleOne;

  LicensePlanPricingBloc({
    required this.getAll,
    required this.createOne,
    required this.updateOne,
    required this.toggleOne,
  }) : super(const LicensePlanPricingState()) {
    on<LoadLicensePlanPricings>(_load);
    on<RefreshLicensePlanPricings>(_load);
    on<AddLicensePlanPricing>(_add);
    on<EditLicensePlanPricing>(_edit);
    on<ToggleLicensePlanPricingActive>(_toggle);
  }

  Future<void> _load(
    LicensePlanPricingEvent _,
    Emitter<LicensePlanPricingState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final items = await getAll();
      emit(state.copyWith(loading: false, items: items));
    } catch (err) {
      emit(state.copyWith(loading: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _add(
    AddLicensePlanPricing event,
    Emitter<LicensePlanPricingState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await createOne(event.pricing);
      final items = await getAll();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Pricing row added successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _edit(
    EditLicensePlanPricing event,
    Emitter<LicensePlanPricingState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await updateOne(event.pricing);
      final items = await getAll();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Pricing row updated successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _toggle(
    ToggleLicensePlanPricingActive event,
    Emitter<LicensePlanPricingState> emit,
  ) async {
    final toggling = {...state.togglingIds, event.id};
    emit(state.copyWith(togglingIds: toggling, error: null, success: null));
    try {
      await toggleOne(id: event.id, isActive: event.isActive);
      final items = await getAll();
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
        togglingIds: done,
        items: items,
        success: event.isActive
            ? 'Pricing row activated.'
            : 'Pricing row deactivated.',
      ));
    } catch (err) {
      final done = {...state.togglingIds}..remove(event.id);
      emit(state.copyWith(
          togglingIds: done, error: ApiErrorHandler.message(err)));
    }
  }
}
