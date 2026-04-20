import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';

class LicensePlanPricing extends Equatable {
  final int id;
  final String planCode;
  final PricingBillingCycle billingCycle;
  final double price;
  final double? discountedPrice;
  final String currency;
  final int? discountPercent;
  final String? discountLabel;
  final bool isActive;
  final DateTime? createdAt;

  const LicensePlanPricing({
    required this.id,
    required this.planCode,
    required this.billingCycle,
    required this.price,
    this.discountedPrice,
    required this.currency,
    this.discountPercent,
    this.discountLabel,
    required this.isActive,
    this.createdAt,
  });

  double get effectivePrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  @override
  List<Object?> get props => [
        id,
        planCode,
        billingCycle,
        price,
        discountedPrice,
        currency,
        discountPercent,
        discountLabel,
        isActive,
        createdAt,
      ];
}
