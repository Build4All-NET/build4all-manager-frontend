import '../../domain/entities/payment_method.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    required super.type,
    required super.provider,
    required super.enabled,
    super.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> j) {
    return PaymentMethodModel(
      id: (j['id'] ?? 0) as int,
      name: (j['name'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      provider: (j['provider'] ?? '').toString(),
      enabled: (j['enabled'] ?? true) as bool,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateBody() => {
        'name': name,
        'type': type,
        'provider': provider,
      };

  Map<String, dynamic> toUpdateBody() => {
        'name': name,
        'type': type,
        'provider': provider,
      };
}
