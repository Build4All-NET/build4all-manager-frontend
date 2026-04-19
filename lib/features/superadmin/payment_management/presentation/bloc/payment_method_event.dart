import 'package:equatable/equatable.dart';

abstract class PaymentMethodEvent extends Equatable {
  const PaymentMethodEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentMethodEvent {}

class RefreshPaymentMethods extends PaymentMethodEvent {}

class AddPaymentMethod extends PaymentMethodEvent {
  final String name;
  final String type;
  final String provider;

  const AddPaymentMethod({
    required this.name,
    required this.type,
    required this.provider,
  });

  @override
  List<Object?> get props => [name, type, provider];
}

class EditPaymentMethod extends PaymentMethodEvent {
  final int id;
  final String name;
  final String type;
  final String provider;

  const EditPaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
  });

  @override
  List<Object?> get props => [id, name, type, provider];
}

class TogglePaymentMethodEnabled extends PaymentMethodEvent {
  final int id;
  final bool enabled;

  const TogglePaymentMethodEnabled({required this.id, required this.enabled});

  @override
  List<Object?> get props => [id, enabled];
}
