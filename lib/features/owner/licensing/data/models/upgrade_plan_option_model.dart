class PlanPricingInfo {
  final double? monthlyPrice;
  final double? yearlyPrice;
  final double? yearlyDiscountedPrice;
  final String? currency;
  final int? discountPercent;
  final String? discountLabel;

  const PlanPricingInfo({
    this.monthlyPrice,
    this.yearlyPrice,
    this.yearlyDiscountedPrice,
    this.currency,
    this.discountPercent,
    this.discountLabel,
  });

  factory PlanPricingInfo.fromJson(Map<String, dynamic> j) => PlanPricingInfo(
        monthlyPrice: _toDouble(j['monthlyPrice']),
        yearlyPrice: _toDouble(j['yearlyPrice']),
        yearlyDiscountedPrice: _toDouble(j['yearlyDiscountedPrice']),
        currency: j['currency']?.toString(),
        discountPercent: j['discountPercent'] != null
            ? int.tryParse(j['discountPercent'].toString())
            : null,
        discountLabel: j['discountLabel']?.toString(),
      );

  static double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  double? get effectiveYearlyPrice => yearlyDiscountedPrice ?? yearlyPrice;
}

class UpgradePlanOptionModel {
  final String code;
  final String title;
  final String? description;
  final bool available;
  final String? unavailableReason;
  final PlanPricingInfo? pricing;

  const UpgradePlanOptionModel({
    required this.code,
    required this.title,
    this.description,
    required this.available,
    this.unavailableReason,
    this.pricing,
  });

  factory UpgradePlanOptionModel.fromJson(Map<String, dynamic> j) =>
      UpgradePlanOptionModel(
        code: j['code']?.toString() ?? '',
        title: j['title']?.toString() ?? j['code']?.toString() ?? '',
        description: j['description']?.toString(),
        available: j['available'] as bool? ?? true,
        unavailableReason: j['unavailableReason']?.toString(),
        pricing: j['pricing'] != null
            ? PlanPricingInfo.fromJson(
                Map<String, dynamic>.from(j['pricing'] as Map))
            : null,
      );
}
