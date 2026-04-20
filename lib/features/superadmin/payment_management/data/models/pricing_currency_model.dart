import '../../domain/entities/pricing_currency.dart';

class PricingCurrencyModel extends PricingCurrency {
  const PricingCurrencyModel({
    required super.id,
    required super.currencyType,
    required super.code,
    super.symbol,
  });

  factory PricingCurrencyModel.fromJson(Map<String, dynamic> j) {
    final id = j['id'] ?? j['currencyId'] ?? 0;
    return PricingCurrencyModel(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      currencyType: (j['currencyType'] ?? '').toString(),
      code: (j['code'] ?? '').toString().toUpperCase(),
      symbol: j['symbol']?.toString(),
    );
  }
}
