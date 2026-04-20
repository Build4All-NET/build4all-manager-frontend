import '../entities/pricing_currency.dart';
import '../repositories/i_license_plan_pricing_repository.dart';

class GetPricingCurrencies {
  final ILicensePlanPricingRepository _repo;
  const GetPricingCurrencies(this._repo);

  Future<List<PricingCurrency>> call() => _repo.listCurrencies();
}
