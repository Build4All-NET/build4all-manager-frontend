class CreatePaymentMethodDto {
  final String paymentDisplayName;
  final String paymentType;
  final String providerCode;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic>? config;

  const CreatePaymentMethodDto({
    required this.paymentDisplayName,
    required this.paymentType,
    required this.providerCode,
    this.description = '',
    this.isEnabled = true,
    this.config,
  });

  Map<String, dynamic> toJson() => {
        'paymentDisplayName': paymentDisplayName,
        'paymentType': paymentType,
        'providerCode': providerCode,
        'description': description,
        'isEnabled': isEnabled,
        if (config != null) 'config': config,
      };
}

class UpdatePaymentMethodDto {
  final String paymentDisplayName;
  final String providerCode;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic>? config;

  const UpdatePaymentMethodDto({
    required this.paymentDisplayName,
    required this.providerCode,
    this.description = '',
    this.isEnabled = true,
    this.config,
  });

  Map<String, dynamic> toJson() => {
        'paymentDisplayName': paymentDisplayName,
        'providerCode': providerCode,
        'description': description,
        'isEnabled': isEnabled,
        if (config != null) 'config': config,
      };
}

class TogglePaymentMethodDto {
  final bool isEnabled;
  const TogglePaymentMethodDto({required this.isEnabled});
  Map<String, dynamic> toJson() => {'isEnabled': isEnabled};
}

class PaymentMethodResponseDto {
  final int id;
  final String paymentDisplayName;
  final String paymentType;
  final String providerCode;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic>? config;
  final String? createdAt;

  const PaymentMethodResponseDto({
    required this.id,
    required this.paymentDisplayName,
    required this.paymentType,
    required this.providerCode,
    this.description = '',
    required this.isEnabled,
    this.config,
    this.createdAt,
  });

  factory PaymentMethodResponseDto.fromJson(Map<String, dynamic> j) =>
      PaymentMethodResponseDto(
        id: (j['id'] ?? 0) as int,
        paymentDisplayName:
            (j['paymentDisplayName'] ?? j['name'] ?? '').toString(),
        paymentType: (j['paymentType'] ?? j['type'] ?? 'CUSTOM').toString(),
        providerCode: (j['providerCode'] ?? j['provider'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        isEnabled: (j['isEnabled'] ?? j['enabled'] ?? true) as bool,
        config: j['config'] is Map
            ? Map<String, dynamic>.from(j['config'] as Map)
            : null,
        createdAt: j['createdAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'paymentDisplayName': paymentDisplayName,
        'paymentType': paymentType,
        'providerCode': providerCode,
        'description': description,
        'isEnabled': isEnabled,
        if (config != null) 'config': config,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
