import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_plan.dart';
import '../../domain/usecases/delete_plan.dart';
import '../../domain/usecases/get_plans.dart';
import '../../domain/usecases/update_plan.dart';
import 'plan_event.dart';
import 'plan_state.dart';

class PlanBloc extends Bloc<PlanEvent, PlanState> {
  final GetPlans getPlans;
  final CreatePlan createPlan;
  final UpdatePlan updatePlan;
  final DeletePlan deletePlan;

  PlanBloc({
    required this.getPlans,
    required this.createPlan,
    required this.updatePlan,
    required this.deletePlan,
  }) : super(const PlanState()) {
    on<LoadPlans>(_load);
    on<RefreshPlans>(_load);
    on<AddPlan>(_add);
    on<EditPlan>(_edit);
    on<DeletePlanEvent>(_delete);
  }

  Future<void> _load(
    PlanEvent _,
    Emitter<PlanState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final items = await getPlans();
      emit(state.copyWith(loading: false, items: items));
    } catch (err) {
      emit(state.copyWith(loading: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _add(
    AddPlan event,
    Emitter<PlanState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await createPlan(event.plan);
      final items = await getPlans();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Plan created successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _edit(
    EditPlan event,
    Emitter<PlanState> emit,
  ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await updatePlan(event.plan);
      final items = await getPlans();
      emit(state.copyWith(
        saving: false,
        items: items,
        success: 'Plan updated successfully.',
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, error: ApiErrorHandler.message(err)));
    }
  }

  Future<void> _delete(
    DeletePlanEvent event,
    Emitter<PlanState> emit,
  ) async {
    final deleting = {...state.deletingCodes, event.code};
    emit(state.copyWith(deletingCodes: deleting, error: null, success: null));
    try {
      await deletePlan(event.code);
      final items = state.items.where((p) => p.code != event.code).toList();
      final done = {...state.deletingCodes}..remove(event.code);
      emit(state.copyWith(
        deletingCodes: done,
        items: items,
        success: 'Plan deleted successfully.',
      ));
    } catch (err) {
      final done = {...state.deletingCodes}..remove(event.code);
      emit(state.copyWith(
          deletingCodes: done, error: ApiErrorHandler.message(err)));
    }
  }
}
