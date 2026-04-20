import '../entities/license_plan_pricing.dart';
import '../repositories/i_license_plan_pricing_repository.dart';

class CreateLicensePlanPricing {
  final ILicensePlanPricingRepository _repo;
  const CreateLicensePlanPricing(this._repo);

  Future<void> call(LicensePlanPricing pricing) => _repo.create(pricing);
}
