import 'package:build4all_manager/features/owner/ownerprofile/domain/usecases/get_owner_profile_usecase.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'owner_profile_event.dart';
import 'owner_profile_state.dart';

class OwnerProfileBloc extends Bloc<OwnerProfileEvent, OwnerProfileState> {
  final GetOwnerProfileUseCase getProfile;

  OwnerProfileBloc({required this.getProfile})
      : super(const OwnerProfileState.initial()) {
    on<OwnerProfileStarted>(_onStarted);
    on<OwnerProfileRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
      OwnerProfileStarted e, Emitter<OwnerProfileState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final profile = await getProfile(adminId: e.adminId);
      emit(state.copyWith(loading: false, profile: profile));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _onRefreshed(
      OwnerProfileRefreshed e, Emitter<OwnerProfileState> emit) async {
    if (state.profile == null) {
      add(const OwnerProfileStarted());
      return;
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      final currentId = state.profile!.adminId;
      final profile = await getProfile(adminId: currentId);
      emit(state.copyWith(loading: false, profile: profile));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}