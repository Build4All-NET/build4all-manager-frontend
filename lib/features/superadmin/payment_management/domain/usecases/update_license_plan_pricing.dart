import '../entities/license_plan_pricing.dart';
import '../repositories/i_license_plan_pricing_repository.dart';

class UpdateLicensePlanPricing {
  final ILicensePlanPricingRepository _repo;
  const UpdateLicensePlanPricing(this._repo);

  Future<void> call(LicensePlanPricing pricing) => _repo.update(pricing);
}
