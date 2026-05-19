import 'package:build4all_manager/features/superadmin/sprint_release/data/services/github_actions_service.dart';
import 'package:build4all_manager/features/superadmin/sprint_release/data/services/pat_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sprint_release_event.dart';
import 'sprint_release_state.dart';

class SprintReleaseBloc
    extends Bloc<SprintReleaseEvent, SprintReleaseState> {
  final GithubActionsService _github;

  SprintReleaseBloc({GithubActionsService? github})
      : _github = github ?? GithubActionsService(),
        super(const SprintReleaseState()) {
    on<SprintReleaseLoadPat>(_onLoadPat);
    on<SprintReleaseSavePat>(_onSavePat);
    on<SprintReleaseClearPat>(_onClearPat);
    on<SprintReleaseTrigger>(_onTrigger);
  }

  Future<void> _onLoadPat(
      SprintReleaseLoadPat e, Emitter<SprintReleaseState> emit) async {
    final pat = await PatStorage.read();
    emit(pat != null
        ? state.copyWith(savedPat: pat)
        : state.copyWith(clearPat: true));
  }

  Future<void> _onSavePat(
      SprintReleaseSavePat e, Emitter<SprintReleaseState> emit) async {
    await PatStorage.write(e.pat);
    emit(state.copyWith(savedPat: e.pat));
  }

  Future<void> _onClearPat(
      SprintReleaseClearPat e, Emitter<SprintReleaseState> emit) async {
    await PatStorage.delete();
    emit(state.copyWith(clearPat: true));
  }

  Future<void> _onTrigger(
      SprintReleaseTrigger e, Emitter<SprintReleaseState> emit) async {
    emit(state.copyWith(
        status: SprintReleaseStatus.loading, clearError: true));
    try {
      await _github.triggerSprintRelease(
        pat: e.pat,
        sprintName: e.sprintName,
      );
      emit(state.copyWith(status: SprintReleaseStatus.success));
    } catch (err) {
      emit(state.copyWith(
        status: SprintReleaseStatus.failure,
        error: err.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
