import '../repositories/i_plan_repository.dart';

class DeletePlan {
  final IPlanRepository _repo;
  const DeletePlan(this._repo);

  Future<void> call(String code) => _repo.delete(code);
}
