import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/delete_owner_account_usecase.dart';
import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/get_owner_profile_usecase.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'owner_profile_event.dart';
import 'owner_profile_state.dart';

class OwnerProfileBloc extends Bloc<OwnerProfileEvent, OwnerProfileState> {
  final GetOwnerProfileUseCase getProfile;
  final DeleteOwnerAccountUseCase deleteAccount;

  OwnerProfileBloc({
    required this.getProfile,
    required this.deleteAccount,
  }) : super(const OwnerProfileState.initial()) {
    on<OwnerProfileStarted>(_onStarted);
    on<OwnerProfileRefreshed>(_onRefreshed);
    on<OwnerProfileDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onStarted(
    OwnerProfileStarted e,
    Emitter<OwnerProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        deleteError: null,
        deleteSuccess: false,
      ),
    );

    try {
      final profile = await getProfile(adminId: e.adminId);

      emit(
        state.copyWith(
          loading: false,
          profile: profile,
          error: null,
          deleteError: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: ApiErrorHandler.message(err),
          deleteError: null,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    OwnerProfileRefreshed e,
    Emitter<OwnerProfileState> emit,
  ) async {
    if (state.profile == null) {
      add(const OwnerProfileStarted());
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        error: null,
        deleteError: null,
      ),
    );

    try {
      final currentId = state.profile!.adminId;
      final profile = await getProfile(adminId: currentId);

      emit(
        state.copyWith(
          loading: false,
          profile: profile,
          error: null,
          deleteError: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: ApiErrorHandler.message(err),
          deleteError: null,
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    OwnerProfileDeleteRequested e,
    Emitter<OwnerProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        deletingAccount: true,
        deleteSuccess: false,
        deleteError: null,
        error: null,
      ),
    );

    try {
      await deleteAccount(password: e.password);

      emit(
        state.copyWith(
          deletingAccount: false,
          deleteSuccess: true,
          deleteError: null,
          error: null,
        ),
      );
    } catch (err) {
  final message = ApiErrorHandler.message(err).trim();
  final lower = message.toLowerCase();

  final friendlyMessage = lower.contains('password') ||
          lower.contains('incorrect') ||
          lower.contains('wrong') ||
          lower.contains('invalid credentials')
      ? 'Incorrect password'
      : message.isEmpty || lower.contains('something went wrong')
          ? 'Unable to delete account. Please try again.'
          : message;

  emit(
    state.copyWith(
      deletingAccount: false,
      deleteSuccess: false,
      deleteError: friendlyMessage,
      error: null,
    ),
  );
}
  }
}