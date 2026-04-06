import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/features/owner/common/domain/usecases/get_my_apps_uc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import 'owner_projects_event.dart';
import 'owner_projects_state.dart';

class OwnerProjectsBloc extends Bloc<OwnerProjectsEvent, OwnerProjectsState> {
  final GetMyAppsUc getMyApps;

  OwnerProjectsBloc({required this.getMyApps})
      : super(const OwnerProjectsState()) {
    on<OwnerProjectsStarted>(_onLoad);
    on<OwnerProjectsRefreshed>(_onLoad);

    on<OwnerProjectsSearchChanged>((e, emit) {
      emit(state.copyWith(query: e.query));
    });

    on<OwnerProjectsToggleOnlyReady>((e, emit) {
      emit(state.copyWith(onlyReady: !state.onlyReady));
    });
  }

  Future<void> _onLoad(
    OwnerProjectsEvent e,
    Emitter<OwnerProjectsState> emit,
  ) async {
    final ownerId = (e is OwnerProjectsStarted)
        ? e.ownerId
        : (e as OwnerProjectsRefreshed).ownerId;

    emit(state.copyWith(loading: true, error: null));

    try {
      final items = await getMyApps();
      emit(state.copyWith(loading: false, all: items, error: null));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}