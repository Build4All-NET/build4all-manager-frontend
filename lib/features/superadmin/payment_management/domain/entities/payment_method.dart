import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final int id;
  final String name;
  final String type;
  final String provider;
  final bool enabled;
  final DateTime? createdAt;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
    required this.enabled,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type, provider, enabled, createdAt];
}
