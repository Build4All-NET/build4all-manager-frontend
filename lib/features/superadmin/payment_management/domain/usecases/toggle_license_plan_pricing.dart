import '../repositories/i_license_plan_pricing_repository.dart';

class ToggleLicensePlanPricing {
  final ILicensePlanPricingRepository _repo;
  const ToggleLicensePlanPricing(this._repo);

  Future<void> call({required int id, required bool isActive}) =>
      _repo.toggle(id: id, isActive: isActive);
}
