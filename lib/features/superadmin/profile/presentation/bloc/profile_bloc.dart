import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/update_password.dart';
import '../../domain/usecases/update_notifications.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetMe getMe;
  final UpdateProfile updateProfile;
  final UpdatePassword updatePassword;
  final UpdateNotifications updateNotifications;

  ProfileBloc({
    required this.getMe,
    required this.updateProfile,
    required this.updatePassword,
    required this.updateNotifications,
  }) : super(const ProfileState()) {
    on<LoadProfile>(_load);
    on<RefreshProfile>(_load);
    on<SubmitProfile>(_submitProfile);
    on<SubmitPassword>(_submitPassword);
    on<SubmitNotifications>(_submitNotifications);
  }

  Future<void> _load(ProfileEvent e, Emitter<ProfileState> emit) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final me = await getMe();
      emit(state.copyWith(loading: false, me: me));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _submitProfile(
    SubmitProfile e,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(savingProfile: true, error: null, success: null));
    try {
      await updateProfile(e.profile);
      final me = await getMe();
      emit(state.copyWith(
        savingProfile: false,
        me: me,
        success: 'Profile updated successfully',
      ));
    } catch (err) {
      emit(state.copyWith(
        savingProfile: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _submitPassword(
    SubmitPassword e,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(savingPassword: true, error: null, success: null));
    try {
      await updatePassword(e.currentPassword, e.newPassword);
      emit(state.copyWith(
        savingPassword: false,
        success: 'Password updated',
      ));
    } catch (err) {
      emit(state.copyWith(
        savingPassword: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _submitNotifications(
    SubmitNotifications e,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(savingNotifications: true, error: null, success: null));
    try {
      await updateNotifications(
        items: e.notifyItems,
        feedback: e.notifyFeedback,
      );
      final me = await getMe();
      emit(state.copyWith(
        savingNotifications: false,
        me: me,
        success: 'Notification settings saved',
      ));
    } catch (err) {
      emit(state.copyWith(
        savingNotifications: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}