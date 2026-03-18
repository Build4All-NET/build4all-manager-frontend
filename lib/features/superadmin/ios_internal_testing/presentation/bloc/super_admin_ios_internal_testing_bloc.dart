import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/super_admin_ios_internal_testing_api.dart';
import 'super_admin_ios_internal_testing_event.dart';
import 'super_admin_ios_internal_testing_state.dart';

class SuperAdminIosInternalTestingBloc extends Bloc<
    SuperAdminIosInternalTestingEvent, SuperAdminIosInternalTestingState> {
  final SuperAdminIosInternalTestingApi api;

  SuperAdminIosInternalTestingBloc({
    required this.api,
  }) : super(const SuperAdminIosInternalTestingState()) {
    on<SuperAdminIosInternalTestingStarted>(_onLoad);
    on<SuperAdminIosInternalTestingRefreshed>(_onLoad);
    on<SuperAdminIosInternalTestingSearchChanged>(_onSearchChanged);
    on<SuperAdminIosInternalTestingStatusChanged>(_onStatusChanged);
    on<SuperAdminIosInternalTestingProcessPressed>(_onProcessPressed);
    on<SuperAdminIosInternalTestingSyncPressed>(_onSyncPressed);
    on<SuperAdminIosInternalTestingSyncAllPressed>(_onSyncAllPressed);
    on<SuperAdminIosInternalTestingErrorCleared>(_onClearError);
    on<SuperAdminIosInternalTestingNoticeCleared>(_onClearNotice);
  }

  Future<void> _onLoad(
    SuperAdminIosInternalTestingEvent event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) async {
    emit(state.copyWith(
      loading: true,
      clearError: true,
      clearNotice: true,
    ));

    try {
      final requests = await api.getRequests();
      emit(state.copyWith(
        loading: false,
        requests: requests,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onSearchChanged(
    SuperAdminIosInternalTestingSearchChanged event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onStatusChanged(
    SuperAdminIosInternalTestingStatusChanged event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) {
    emit(state.copyWith(selectedStatus: event.status));
  }

  Future<void> _onProcessPressed(
    SuperAdminIosInternalTestingProcessPressed event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) async {
    emit(state.copyWith(
      acting: true,
      actionRequestId: event.requestId,
      clearError: true,
      clearNotice: true,
    ));

    try {
      await api.processRequest(event.requestId);
      final requests = await api.getRequests();

      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        requests: requests,
        notice: SuperAdminIosInternalTestingNotice.processSuccess,
      ));
    } catch (e) {
      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSyncPressed(
    SuperAdminIosInternalTestingSyncPressed event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) async {
    emit(state.copyWith(
      acting: true,
      actionRequestId: event.requestId,
      clearError: true,
      clearNotice: true,
    ));

    try {
      await api.syncRequest(event.requestId);
      final requests = await api.getRequests();

      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        requests: requests,
        notice: SuperAdminIosInternalTestingNotice.syncSuccess,
      ));
    } catch (e) {
      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSyncAllPressed(
    SuperAdminIosInternalTestingSyncAllPressed event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) async {
    final ids = state.filteredRequests
        .where((e) => e.isSyncable)
        .map((e) => e.id)
        .toList();

    if (ids.isEmpty) {
      emit(state.copyWith(
        notice: SuperAdminIosInternalTestingNotice.noSyncableVisible,
        syncAllUpdatedCount: 0,
      ));
      return;
    }

    emit(state.copyWith(
      acting: true,
      clearError: true,
      clearNotice: true,
    ));

    try {
      final updated = await api.syncAll(ids);
      final requests = await api.getRequests();

      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        requests: requests,
        notice: SuperAdminIosInternalTestingNotice.syncAllFinished,
        syncAllUpdatedCount: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
        acting: false,
        clearActionRequestId: true,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onClearError(
    SuperAdminIosInternalTestingErrorCleared event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onClearNotice(
    SuperAdminIosInternalTestingNoticeCleared event,
    Emitter<SuperAdminIosInternalTestingState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}