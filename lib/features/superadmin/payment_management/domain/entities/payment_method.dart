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

  /// Raw payment-type code as returned by the backend / chosen in the
  /// form. Use this in preference to {@link paymentType.code} when the
  /// user can create custom types (e.g. {@code MPGS}) — the enum's
  /// {@link PaymentType.custom} fallback would otherwise silently
  /// downgrade them all to {@code CUSTOM}.
  final String? paymentTypeCode;

  const PaymentMethod({
    required this.id,
    required this.paymentDisplayName,
    required this.paymentType,
    required this.providerCode,
    this.description = '',
    required this.isEnabled,
    this.config,
    this.createdAt,
    this.paymentTypeCode,
  });

  /// Effective code to send to the backend. Prefers the explicit
  /// {@link paymentTypeCode} (filled in by the form when the user picks
  /// a backend-defined type), and falls back to the legacy enum code.
  String get effectiveTypeCode =>
      (paymentTypeCode != null && paymentTypeCode!.isNotEmpty)
          ? paymentTypeCode!
          : paymentType.code;

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
        paymentTypeCode,
      ];
}
