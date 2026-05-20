import 'package:equatable/equatable.dart';

import '../../domain/entities/plan.dart';

abstract class PlanEvent extends Equatable {
  const PlanEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlans extends PlanEvent {}

class RefreshPlans extends PlanEvent {}

class AddPlan extends PlanEvent {
  final Plan plan;
  const AddPlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class EditPlan extends PlanEvent {
  final Plan plan;
  const EditPlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class DeletePlanEvent extends PlanEvent {
  final String code;
  const DeletePlanEvent(this.code);

  @override
  List<Object?> get props => [code];
}
