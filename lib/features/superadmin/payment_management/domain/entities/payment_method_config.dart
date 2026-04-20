sealed class PaymentMethodConfig {
  const PaymentMethodConfig();
  Map<String, dynamic> toJson();

  static PaymentMethodConfig fromType(
    String type,
    Map<String, dynamic> data,
  ) =>
      switch (type.toUpperCase()) {
        'CASH' => CashConfig.fromJson(data),
        'PAYPAL' => PayPalConfig.fromJson(data),
        'STRIPE' => StripeConfig.fromJson(data),
        'VISA' => VisaConfig.fromJson(data),
        _ => CustomConfig.fromJson(data),
      };
}

class CashConfig extends PaymentMethodConfig {
  final String instructions;
  const CashConfig({this.instructions = ''});

  factory CashConfig.fromJson(Map<String, dynamic> j) =>
      CashConfig(instructions: (j['instructions'] ?? '').toString());

  @override
  Map<String, dynamic> toJson() => {'instructions': instructions};
}

class PayPalConfig extends PaymentMethodConfig {
  final String clientId;
  final String secret;
  final bool sandbox;

  const PayPalConfig({
    this.clientId = '',
    this.secret = '',
    this.sandbox = false,
  });

  factory PayPalConfig.fromJson(Map<String, dynamic> j) => PayPalConfig(
        clientId: (j['clientId'] ?? '').toString(),
        secret: (j['secret'] ?? '').toString(),
        sandbox: (j['sandbox'] ?? false) as bool,
      );

  @override
  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'secret': secret,
        'sandbox': sandbox,
      };
}

class StripeConfig extends PaymentMethodConfig {
  final String publishableKey;
  final String secretKey;

  const StripeConfig({this.publishableKey = '', this.secretKey = ''});

  factory StripeConfig.fromJson(Map<String, dynamic> j) => StripeConfig(
        publishableKey: (j['publishableKey'] ?? '').toString(),
        secretKey: (j['secretKey'] ?? '').toString(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'publishableKey': publishableKey,
        'secretKey': secretKey,
      };
}

class VisaConfig extends PaymentMethodConfig {
  final String merchantId;
  final String terminalId;

  const VisaConfig({this.merchantId = '', this.terminalId = ''});

  factory VisaConfig.fromJson(Map<String, dynamic> j) => VisaConfig(
        merchantId: (j['merchantId'] ?? '').toString(),
        terminalId: (j['terminalId'] ?? '').toString(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        'terminalId': terminalId,
      };
}

class CustomConfig extends PaymentMethodConfig {
  final Map<String, String> fields;
  const CustomConfig({this.fields = const {}});

  factory CustomConfig.fromJson(Map<String, dynamic> j) =>
      CustomConfig(fields: j.map((k, v) => MapEntry(k, v.toString())));

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(fields);
}
