import '../../domain/entities/plan.dart';
import '../../domain/repositories/i_plan_repository.dart';
import '../models/plan_model.dart';
import '../services/plan_api.dart';

class PlanRepositoryImpl implements IPlanRepository {
  final PlanApi _api;
  PlanRepositoryImpl(this._api);

  @override
  Future<List<Plan>> getAll() => _api.getAll();

  @override
  Future<void> create(Plan plan) =>
      _api.create(PlanModel.fromEntity(plan).toCreateBody());

  @override
  Future<void> update(Plan plan) =>
      _api.update(plan.code, PlanModel.fromEntity(plan).toUpdateBody());

  @override
  Future<void> delete(String code) => _api.delete(code);
}
