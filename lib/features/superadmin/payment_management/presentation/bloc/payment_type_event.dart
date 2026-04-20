import 'package:equatable/equatable.dart';

import '../../domain/entities/managed_payment_type.dart';

abstract class PaymentTypeEvent extends Equatable {
  const PaymentTypeEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentTypes extends PaymentTypeEvent {}

class RefreshPaymentTypes extends PaymentTypeEvent {}

class AddPaymentType extends PaymentTypeEvent {
  final ManagedPaymentType type;
  const AddPaymentType(this.type);

  @override
  List<Object?> get props => [type];
}

class EditPaymentType extends PaymentTypeEvent {
  final ManagedPaymentType type;
  const EditPaymentType(this.type);

  @override
  List<Object?> get props => [type];
}

class TogglePaymentTypeActive extends PaymentTypeEvent {
  final int id;
  final bool isActive;
  const TogglePaymentTypeActive({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}
