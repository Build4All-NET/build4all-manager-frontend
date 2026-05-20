import '../entities/plan.dart';

abstract class IPlanRepository {
  Future<List<Plan>> getAll();
  Future<void> create(Plan plan);
  Future<void> update(Plan plan);
  Future<void> delete(String code);
}
