import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/license_plan_pricing.dart';

class LicensePlanPricingModel extends LicensePlanPricing {
  const LicensePlanPricingModel({
    required super.id,
    required super.planCode,
    required super.billingCycle,
    required super.price,
    super.discountedPrice,
    required super.currency,
    super.discountPercent,
    super.discountLabel,
    required super.isActive,
    super.createdAt,
  });

  static double _d(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static double? _dNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _iNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory LicensePlanPricingModel.fromJson(Map<String, dynamic> j) {
    return LicensePlanPricingModel(
      id: _iNullable(j['id']) ?? 0,
      planCode: (j['planCode'] ?? '').toString().toUpperCase(),
      billingCycle: PricingBillingCycleX.fromCode(
          (j['billingCycle'] ?? 'MONTHLY').toString()),
      price: _d(j['price']),
      discountedPrice: _dNullable(j['discountedPrice']),
      currency: (j['currency'] ?? 'USD').toString().toUpperCase(),
      discountPercent: _iNullable(j['discountPercent']),
      discountLabel: j['discountLabel']?.toString(),
      isActive: (j['isActive'] ?? j['active'] ?? true) as bool,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }

  factory LicensePlanPricingModel.fromEntity(LicensePlanPricing e) =>
      LicensePlanPricingModel(
        id: e.id,
        planCode: e.planCode,
        billingCycle: e.billingCycle,
        price: e.price,
        discountedPrice: e.discountedPrice,
        currency: e.currency,
        discountPercent: e.discountPercent,
        discountLabel: e.discountLabel,
        isActive: e.isActive,
        createdAt: e.createdAt,
      );

  /// POST body — includes plan + cycle (required on create).
  Map<String, dynamic> toCreateBody() => {
        'planCode': planCode,
        'billingCycle': billingCycle.code,
        'price': price,
        if (discountedPrice != null) 'discountedPrice': discountedPrice,
        'currency': currency,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (discountLabel != null && discountLabel!.isNotEmpty)
          'discountLabel': discountLabel,
        'isActive': isActive,
      };

  /// PUT body — plan + cycle are immutable after create.
  Map<String, dynamic> toUpdateBody() => {
        'price': price,
        if (discountedPrice != null) 'discountedPrice': discountedPrice,
        'currency': currency,
        if (discountPercent != null) 'discountPercent': discountPercent,
        if (discountLabel != null) 'discountLabel': discountLabel,
      };
}
