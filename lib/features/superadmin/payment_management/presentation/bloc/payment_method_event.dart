import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_method.dart';

abstract class PaymentMethodEvent extends Equatable {
  const PaymentMethodEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentMethodEvent {}

class RefreshPaymentMethods extends PaymentMethodEvent {}

class AddPaymentMethod extends PaymentMethodEvent {
  final PaymentMethod method;
  const AddPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class EditPaymentMethod extends PaymentMethodEvent {
  final PaymentMethod method;
  const EditPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class TogglePaymentMethodEnabled extends PaymentMethodEvent {
  final int id;
  final bool isEnabled;
  const TogglePaymentMethodEnabled({
    required this.id,
    required this.isEnabled,
  });

  @override
  List<Object?> get props => [id, isEnabled];
}
