import 'package:equatable/equatable.dart';

abstract class OwnerProfileEvent extends Equatable {
  const OwnerProfileEvent();

  @override
  List<Object?> get props => [];
}

class OwnerProfileStarted extends OwnerProfileEvent {
  final int? adminId;

  const OwnerProfileStarted({this.adminId});

  @override
  List<Object?> get props => [adminId];
}

class OwnerProfileRefreshed extends OwnerProfileEvent {
  const OwnerProfileRefreshed();
}

class OwnerProfileDeleteRequested extends OwnerProfileEvent {
  final String password;

  const OwnerProfileDeleteRequested({required this.password});

  @override
  List<Object?> get props => [password];
}