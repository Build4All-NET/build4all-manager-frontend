import 'package:equatable/equatable.dart';

abstract class OwnerProjectsEvent extends Equatable {
  const OwnerProjectsEvent();
  @override
  List<Object?> get props => [];
}

class OwnerProjectsStarted extends OwnerProjectsEvent {
  final int ownerId;
  const OwnerProjectsStarted(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

class OwnerProjectsRefreshed extends OwnerProjectsEvent {
  final int ownerId;
  const OwnerProjectsRefreshed(this.ownerId);

  @override
  List<Object?> get props => [ownerId];
}

class OwnerProjectsSearchChanged extends OwnerProjectsEvent {
  final String query;
  const OwnerProjectsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class OwnerProjectsToggleOnlyReady extends OwnerProjectsEvent {
  const OwnerProjectsToggleOnlyReady();
}