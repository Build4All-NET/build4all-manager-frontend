import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String identifier; // email or username
  final String password;
  LoginSubmitted(this.identifier, this.password);

  @override
  List<Object?> get props => [identifier, password];
}


class ReactivateAdminDeletionSubmitted extends AuthEvent {
  final String identifier;
  final String password;

  ReactivateAdminDeletionSubmitted(this.identifier, this.password);

  @override
  List<Object?> get props => [identifier, password];
}

class LoggedOut extends AuthEvent {}

class CheckSession extends AuthEvent {}
