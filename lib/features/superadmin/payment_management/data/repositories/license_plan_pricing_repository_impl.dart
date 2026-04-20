import '../../domain/entities/license_plan_pricing.dart';
import '../../domain/entities/pricing_currency.dart';
import '../../domain/repositories/i_license_plan_pricing_repository.dart';
import '../models/license_plan_pricing_model.dart';
import '../services/license_plan_pricing_api.dart';

class LicensePlanPricingRepositoryImpl
    implements ILicensePlanPricingRepository {
  final LicensePlanPricingApi _api;
  LicensePlanPricingRepositoryImpl(this._api);

  @override
  Future<List<LicensePlanPricing>> getAll() => _api.getAll();

  @override
  Future<void> create(LicensePlanPricing pricing) => _api.create(
        LicensePlanPricingModel.fromEntity(pricing).toCreateBody(),
      );

  @override
  Future<void> update(LicensePlanPricing pricing) => _api.update(
        pricing.id,
        LicensePlanPricingModel.fromEntity(pricing).toUpdateBody(),
      );

  @override
  Future<void> toggle({required int id, required bool isActive}) =>
      _api.toggle(id, isActive);

  @override
  Future<List<PricingCurrency>> listCurrencies() => _api.listCurrencies();
}
