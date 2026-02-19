import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/features/auth/domain/usecases/OwnerSendOtp.dart';
import 'package:build4all_manager/features/auth/domain/usecases/OwnerVerifyOtp.dart';
import 'package:build4all_manager/features/auth/domain/usecases/OwnerCompleteProfile.dart';

import 'owner_register_event.dart';
import 'owner_register_state.dart';

class OwnerRegisterBloc extends Bloc<OwnerRegisterEvent, OwnerRegisterState> {
  final OwnerSendOtpUseCase sendOtp;
  final OwnerVerifyOtpUseCase verifyOtp;
  final OwnerCompleteProfileUseCase completeProfile;

  OwnerRegisterBloc(
    this.sendOtp,
    this.verifyOtp,
    this.completeProfile,
  ) : super(OwnerRegisterInitial) {
    on<OwnerSendOtp>(_onSendOtp);
    on<OwnerVerifyOtp>(_onVerifyOtp);
    on<OwnerCompleteProfile>(_onComplete);
  }

  String _cleanErr(Object err) {
    final s = err.toString();
    return s.startsWith('Exception: ') ? s.replaceFirst('Exception: ', '') : s;
  }

  Future<void> _onSendOtp(
      OwnerSendOtp e, Emitter<OwnerRegisterState> emit) async {
    emit(state.copyWith(loading: true, error: null)); // ✅ now actually clears
    try {
      await sendOtp(e.email, e.password);
      emit(state.copyWith(loading: false, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: _cleanErr(err)));
    }
  }

  Future<void> _onVerifyOtp(
      OwnerVerifyOtp e, Emitter<OwnerRegisterState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final token = await verifyOtp(e.email, e.password, e.code);
      emit(state.copyWith(loading: false, registrationToken: token, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: _cleanErr(err)));
    }
  }

  Future<void> _onComplete(
      OwnerCompleteProfile e, Emitter<OwnerRegisterState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await completeProfile(
        registrationToken: e.registrationToken,
        username: e.username,
        firstName: e.firstName,
        lastName: e.lastName,
        phoneNumber: e.phoneNumber,
      );
      emit(state.copyWith(loading: false, completed: true, error: null));
    } catch (err) {
      emit(state.copyWith(loading: false, error: _cleanErr(err)));
    }
  }
}
