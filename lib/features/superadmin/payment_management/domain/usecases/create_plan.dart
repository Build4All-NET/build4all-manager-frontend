import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

class CreatePlan {
  final IPlanRepository _repo;
  const CreatePlan(this._repo);

  Future<void> call(Plan plan) => _repo.create(plan);
}
