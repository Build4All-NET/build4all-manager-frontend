import 'package:equatable/equatable.dart';

sealed class OwnerRegisterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Step 1: send code to email
class OwnerSendOtp extends OwnerRegisterEvent {
  final String email;
  final String password; // plain (backend hashes server-side)
  OwnerSendOtp(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

/// Step 2: verify the 6-digit code and get registration token
class OwnerVerifyOtp extends OwnerRegisterEvent {
  final String email;
  final String password;
  final String code; // 6 digits
  OwnerVerifyOtp(this.email, this.password, this.code);

  @override
  List<Object?> get props => [email, password, code];
}

/// Step 3: finish profile using the short-lived registration token
class OwnerCompleteProfile extends OwnerRegisterEvent {
  final String registrationToken;
  final String username;
  final String firstName;
  final String lastName;
  final String phoneNumber;

  OwnerCompleteProfile(
    this.registrationToken,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  );

  @override
  List<Object?> get props =>
      [registrationToken, username, firstName, lastName, phoneNumber];
}
