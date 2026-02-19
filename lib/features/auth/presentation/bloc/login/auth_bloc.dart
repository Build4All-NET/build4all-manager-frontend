import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/core/exceptions/auth_failure.dart';

import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_role_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetStoredRoleUseCase getRoleUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getRoleUseCase,
  }) : super(AuthInitial) {
    on<LoginSubmitted>(_onLogin);
    on<LoggedOut>(_onLogout);
    on<CheckSession>(_onCheck);
  }

  Future<void> _onLogin(LoginSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(
      loading: true,
      error: null,
      errorCode: null,
      role: null, // ✅ clear any old role
    ));

    try {
      await loginUseCase(e.identifier, e.password);
      final role = await getRoleUseCase();

      emit(state.copyWith(
        loading: false,
        role: role,
        error: null,
        errorCode: null,
      ));
    } catch (err) {
      if (err is AuthFailure) {
        emit(state.copyWith(
          loading: false,
          role: null,
          error: err.message,     // ✅ clean
          errorCode: err.code,    // ✅ for mapping if you want
        ));
      } else {
        final msg = err.toString().replaceFirst('Exception: ', '');
        emit(state.copyWith(
          loading: false,
          role: null,
          error: msg,
          errorCode: 'UNKNOWN',
        ));
      }
    }
  }

  Future<void> _onLogout(LoggedOut e, Emitter<AuthState> emit) async {
    await logoutUseCase();
    emit(const AuthState(loading: false, role: null, error: null, errorCode: null));
  }

  Future<void> _onCheck(CheckSession e, Emitter<AuthState> emit) async {
    final role = await getRoleUseCase();
    emit(state.copyWith(role: (role.isEmpty ? null : role)));
  }
}
