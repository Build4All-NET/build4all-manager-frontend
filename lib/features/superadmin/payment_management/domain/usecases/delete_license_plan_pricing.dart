import '../repositories/i_license_plan_pricing_repository.dart';

class DeleteLicensePlanPricing {
  final ILicensePlanPricingRepository _repo;
  const DeleteLicensePlanPricing(this._repo);

  Future<void> call(int id) => _repo.delete(id);
}
