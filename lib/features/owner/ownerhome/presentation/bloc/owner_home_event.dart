import 'package:equatable/equatable.dart';

abstract class OwnerHomeEvent extends Equatable {
  const OwnerHomeEvent();
  @override
  List<Object?> get props => [];
}

class OwnerHomeStarted extends OwnerHomeEvent {
  final int ownerId;
  const OwnerHomeStarted(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

class OwnerHomeRefreshed extends OwnerHomeEvent {
  final int ownerId;
  const OwnerHomeRefreshed(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}
