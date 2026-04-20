enum PaymentType {
  cash,
  paypal,
  stripe,
  visa,
  bankTransfer,
  custom;

  String get displayName => switch (this) {
        PaymentType.cash => 'Cash',
        PaymentType.paypal => 'PayPal',
        PaymentType.stripe => 'Stripe',
        PaymentType.visa => 'VISA',
        PaymentType.bankTransfer => 'Bank Transfer',
        PaymentType.custom => 'Custom',
      };

  String get code => switch (this) {
        PaymentType.cash => 'CASH',
        PaymentType.paypal => 'PAYPAL',
        PaymentType.stripe => 'STRIPE',
        PaymentType.visa => 'VISA',
        PaymentType.bankTransfer => 'BANK_TRANSFER',
        PaymentType.custom => 'CUSTOM',
      };

  static PaymentType fromCode(String code) => switch (code.toUpperCase()) {
        'CASH' => PaymentType.cash,
        'PAYPAL' => PaymentType.paypal,
        'STRIPE' => PaymentType.stripe,
        'VISA' => PaymentType.visa,
        'BANK_TRANSFER' => PaymentType.bankTransfer,
        _ => PaymentType.custom,
      };
}
