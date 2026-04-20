import 'package:equatable/equatable.dart';

import 'payment_method_config.dart';
import 'payment_type.dart';

class PaymentMethod extends Equatable {
  final int id;
  final String paymentDisplayName;
  final PaymentType paymentType;
  final String providerCode;
  final String description;
  final bool isEnabled;
  final PaymentMethodConfig? config;
  final DateTime? createdAt;

  const PaymentMethod({
    required this.id,
    required this.paymentDisplayName,
    required this.paymentType,
    required this.providerCode,
    this.description = '',
    required this.isEnabled,
    this.config,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        paymentDisplayName,
        paymentType,
        providerCode,
        description,
        isEnabled,
        config,
        createdAt,
      ];
}
