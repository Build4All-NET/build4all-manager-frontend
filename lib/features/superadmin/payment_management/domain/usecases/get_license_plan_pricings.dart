import '../entities/license_plan_pricing.dart';
import '../repositories/i_license_plan_pricing_repository.dart';

class GetLicensePlanPricings {
  final ILicensePlanPricingRepository _repo;
  const GetLicensePlanPricings(this._repo);

  Future<List<LicensePlanPricing>> call() => _repo.getAll();
}
