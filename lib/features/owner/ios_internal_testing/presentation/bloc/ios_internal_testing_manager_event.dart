import 'package:equatable/equatable.dart';

abstract class IosInternalTestingManagerEvent extends Equatable {
  const IosInternalTestingManagerEvent();

  @override
  List<Object?> get props => [];
}

class IosInternalTestingManagerStarted
    extends IosInternalTestingManagerEvent {
  final int linkId;

  const IosInternalTestingManagerStarted({
    required this.linkId,
  });

  @override
  List<Object?> get props => [linkId];
}

class IosInternalTestingManagerRefreshed
    extends IosInternalTestingManagerEvent {
  final int linkId;

  const IosInternalTestingManagerRefreshed({
    required this.linkId,
  });

  @override
  List<Object?> get props => [linkId];
}

class IosInternalTestingManagerSubmitted
    extends IosInternalTestingManagerEvent {
  final int linkId;
  final String appleEmail;
  final String firstName;
  final String lastName;

  const IosInternalTestingManagerSubmitted({
    required this.linkId,
    required this.appleEmail,
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [linkId, appleEmail, firstName, lastName];
}

class IosInternalTestingManagerMessageCleared
    extends IosInternalTestingManagerEvent {
  const IosInternalTestingManagerMessageCleared();
}

class IosInternalTestingManagerErrorCleared
    extends IosInternalTestingManagerEvent {
  const IosInternalTestingManagerErrorCleared();
}