import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool loading;
  final String? role;
  final String? error;
  final String? errorCode;

  const AuthState({
    this.loading = false,
    this.role,
    this.error,
    this.errorCode,
  });

  static const _unset = Object();

  AuthState copyWith({
    bool? loading,
    Object? role = _unset,
    Object? error = _unset,
    Object? errorCode = _unset,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      role: role == _unset ? this.role : role as String?,
      error: error == _unset ? this.error : error as String?,
      errorCode: errorCode == _unset ? this.errorCode : errorCode as String?,
    );
  }

  @override
  List<Object?> get props => [loading, role, error, errorCode];
}

const AuthInitial = AuthState();
