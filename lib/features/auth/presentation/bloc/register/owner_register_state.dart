import 'package:equatable/equatable.dart';

class OwnerRegisterState extends Equatable {
  final bool loading;
  final String? error; // toast this on UI if present
  final String? registrationToken; // set after OTP is verified
  final bool completed; // true after profile creation success

  const OwnerRegisterState({
    this.loading = false,
    this.error,
    this.registrationToken,
    this.completed = false,
  });

  // Sentinel to allow "set to null" vs "don't change"
  static const Object _unset = Object();

  OwnerRegisterState copyWith({
    bool? loading,
    Object? error = _unset,
    Object? registrationToken = _unset,
    bool? completed,
  }) {
    return OwnerRegisterState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      registrationToken: identical(registrationToken, _unset)
          ? this.registrationToken
          : registrationToken as String?,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [loading, error, registrationToken, completed];
}

const OwnerRegisterInitial = OwnerRegisterState();
