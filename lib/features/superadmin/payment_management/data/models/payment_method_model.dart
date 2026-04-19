import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_config.dart';
import '../../domain/entities/payment_type.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.paymentDisplayName,
    required super.paymentType,
    required super.providerCode,
    super.description = '',
    required super.isEnabled,
    super.config,
    super.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> j) {
    final typeCode = (j['paymentType'] ?? j['type'] ?? 'CUSTOM').toString();
    final configData = j['config'] is Map
        ? Map<String, dynamic>.from(j['config'] as Map)
        : <String, dynamic>{};
    return PaymentMethodModel(
      id: (j['id'] ?? 0) as int,
      paymentDisplayName:
          (j['paymentDisplayName'] ?? j['name'] ?? '').toString(),
      paymentType: PaymentType.fromCode(typeCode),
      providerCode: (j['providerCode'] ?? j['provider'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      isEnabled: (j['isEnabled'] ?? j['enabled'] ?? true) as bool,
      config: PaymentMethodConfig.fromType(typeCode, configData),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }

  factory PaymentMethodModel.fromEntity(PaymentMethod m) =>
      PaymentMethodModel(
        id: m.id,
        paymentDisplayName: m.paymentDisplayName,
        paymentType: m.paymentType,
        providerCode: m.providerCode,
        description: m.description,
        isEnabled: m.isEnabled,
        config: m.config,
        createdAt: m.createdAt,
      );

  Map<String, dynamic> toCreateBody() => {
        'paymentDisplayName': paymentDisplayName,
        'paymentType': paymentType.code,
        'providerCode': providerCode,
        'description': description,
        'isEnabled': isEnabled,
        if (config != null) 'config': config!.toJson(),
      };

  Map<String, dynamic> toUpdateBody() => toCreateBody();
}
