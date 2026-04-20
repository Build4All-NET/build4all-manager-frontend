import '../entities/license_plan_pricing.dart';
import '../entities/pricing_currency.dart';

abstract class ILicensePlanPricingRepository {
  Future<List<LicensePlanPricing>> getAll();
  Future<void> create(LicensePlanPricing pricing);
  Future<void> update(LicensePlanPricing pricing);
  Future<void> toggle({required int id, required bool isActive});

  /// Populates the currency dropdown in the pricing form.
  Future<List<PricingCurrency>> listCurrencies();
}
