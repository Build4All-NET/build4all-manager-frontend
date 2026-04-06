import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final IDashboardRepository repo;

  DashboardBloc(this.repo) : super(const DashboardState()) {
    on<LoadDashboard>(_load);
    on<RefreshDashboard>(_load);
  }

  Future<void> _load(DashboardEvent e, Emitter<DashboardState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final (overview, recent) = await repo.load();
      emit(state.copyWith(
        loading: false,
        overview: overview,
        recent: recent,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}