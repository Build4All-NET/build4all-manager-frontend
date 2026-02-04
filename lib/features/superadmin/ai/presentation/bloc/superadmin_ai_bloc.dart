import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_owner_ai_status.dart';
import '../../domain/usecases/toggle_owner_ai.dart';
import 'superadmin_ai_event.dart';
import 'superadmin_ai_state.dart';

class SuperAdminAiBloc extends Bloc<SuperAdminAiEvent, SuperAdminAiState> {
  final GetOwnerAiStatus getStatus;
  final ToggleOwnerAi toggle;

  SuperAdminAiBloc({
    required this.getStatus,
    required this.toggle,
  }) : super(SuperAdminAiState.initial()) {
    on<SuperAdminAiStarted>(_onStarted);
    on<SuperAdminAiToggled>(_onToggled);
  }

  Future<void> _onStarted(
    SuperAdminAiStarted e,
    Emitter<SuperAdminAiState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final s = await getStatus(ownerId: e.ownerId);
      emit(state.copyWith(loading: false, status: s));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onToggled(
  SuperAdminAiToggled e,
  Emitter<SuperAdminAiState> emit,
) async {
  final old = state.status;

  emit(state.copyWith(
    updating: true,
    clearError: true,
    status: old?.copyWith(aiEnabled: e.enabled),
  ));

  try {
    final s = await toggle(ownerId: e.ownerId, enabled: e.enabled);
    emit(state.copyWith(updating: false, status: s));
  } catch (err) {
    emit(state.copyWith(updating: false, error: err.toString(), status: old));
  }
}
}

extension _CopyOwnerAiStatus on dynamic {
  // ignore: unused_element
  dynamic copyWith() => this;
}
