import 'package:equatable/equatable.dart';

abstract class SuperAdminIosInternalTestingEvent extends Equatable {
  const SuperAdminIosInternalTestingEvent();

  @override
  List<Object?> get props => [];
}

class SuperAdminIosInternalTestingStarted
    extends SuperAdminIosInternalTestingEvent {
  const SuperAdminIosInternalTestingStarted();
}

class SuperAdminIosInternalTestingRefreshed
    extends SuperAdminIosInternalTestingEvent {
  const SuperAdminIosInternalTestingRefreshed();
}

class SuperAdminIosInternalTestingSearchChanged
    extends SuperAdminIosInternalTestingEvent {
  final String query;

  const SuperAdminIosInternalTestingSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SuperAdminIosInternalTestingStatusChanged
    extends SuperAdminIosInternalTestingEvent {
  final String status;

  const SuperAdminIosInternalTestingStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class SuperAdminIosInternalTestingProcessPressed
    extends SuperAdminIosInternalTestingEvent {
  final int requestId;

  const SuperAdminIosInternalTestingProcessPressed(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class SuperAdminIosInternalTestingSyncPressed
    extends SuperAdminIosInternalTestingEvent {
  final int requestId;

  const SuperAdminIosInternalTestingSyncPressed(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class SuperAdminIosInternalTestingSyncAllPressed
    extends SuperAdminIosInternalTestingEvent {
  const SuperAdminIosInternalTestingSyncAllPressed();
}

class SuperAdminIosInternalTestingErrorCleared
    extends SuperAdminIosInternalTestingEvent {
  const SuperAdminIosInternalTestingErrorCleared();
}

class SuperAdminIosInternalTestingNoticeCleared
    extends SuperAdminIosInternalTestingEvent {
  const SuperAdminIosInternalTestingNoticeCleared();
}