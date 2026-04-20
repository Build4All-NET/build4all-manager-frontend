enum PricingBillingCycle { monthly, yearly }

extension PricingBillingCycleX on PricingBillingCycle {
  String get code => switch (this) {
        PricingBillingCycle.monthly => 'MONTHLY',
        PricingBillingCycle.yearly => 'YEARLY',
      };

  String get displayName => switch (this) {
        PricingBillingCycle.monthly => 'Monthly',
        PricingBillingCycle.yearly => 'Yearly',
      };

  static PricingBillingCycle fromCode(String code) =>
      switch (code.toUpperCase()) {
        'YEARLY' => PricingBillingCycle.yearly,
        _ => PricingBillingCycle.monthly,
      };
}
