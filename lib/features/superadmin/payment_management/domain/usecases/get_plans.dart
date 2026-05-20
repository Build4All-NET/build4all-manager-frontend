import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

class GetPlans {
  final IPlanRepository _repo;
  const GetPlans(this._repo);

  Future<List<Plan>> call() => _repo.getAll();
}
