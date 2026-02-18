import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/owner_profile.dart';
import '../../domain/usecases/update_owner_profile_usecase.dart';

class OwnerProfileEditState {
  final bool saving;
  final Object? error;
  final OwnerProfile? updated;


  const OwnerProfileEditState({
    required this.saving,
    this.error,
    this.updated,
  });

  const OwnerProfileEditState.initial()
      : saving = false,
        error = null,
        updated = null;

OwnerProfileEditState copyWith({
  bool? saving,
  Object? error,
  OwnerProfile? updated,
}) {
  return OwnerProfileEditState(
    saving: saving ?? this.saving,
    error: error,
    updated: updated,
  );
}

}

class OwnerProfileEditCubit extends Cubit<OwnerProfileEditState> {
  final UpdateOwnerProfileUseCase update;
  OwnerProfileEditCubit({required this.update})
      : super(const OwnerProfileEditState.initial());

  Future<void> save(Map<String, dynamic> body) async {
    emit(state.copyWith(saving: true, error: null, updated: null));
    try {
      final res = await update(body);
      emit(state.copyWith(saving: false, updated: res));
    } catch (e) {
  emit(state.copyWith(saving: false, error: e));
}

  }
}
