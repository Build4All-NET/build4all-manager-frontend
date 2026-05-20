import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

class UpdatePlan {
  final IPlanRepository _repo;
  const UpdatePlan(this._repo);

  Future<void> call(Plan plan) => _repo.update(plan);
}
