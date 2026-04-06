import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import '../../domain/entities/ios_internal_testing_app_summary.dart';
import '../../domain/usecases/create_ios_internal_testing_request_uc.dart';
import '../../domain/usecases/get_ios_internal_testing_app_summary_uc.dart';
import 'ios_internal_testing_manager_event.dart';
import 'ios_internal_testing_manager_state.dart';

class IosInternalTestingManagerBloc extends Bloc<
    IosInternalTestingManagerEvent, IosInternalTestingManagerState> {
  final CreateIosInternalTestingRequestUc createRequestUc;
  final GetIosInternalTestingAppSummaryUc getSummaryUc;

  IosInternalTestingManagerBloc({
    required this.createRequestUc,
    required this.getSummaryUc,
  }) : super(const IosInternalTestingManagerState()) {
    on<IosInternalTestingManagerStarted>(_onLoadSummary);
    on<IosInternalTestingManagerRefreshed>(_onLoadSummary);
    on<IosInternalTestingManagerSubmitted>(_onSubmit);
    on<IosInternalTestingManagerMessageCleared>(_onClearMessage);
    on<IosInternalTestingManagerErrorCleared>(_onClearError);
  }

  Future<void> _onLoadSummary(
    IosInternalTestingManagerEvent event,
    Emitter<IosInternalTestingManagerState> emit,
  ) async {
    final int? linkId = switch (event) {
      IosInternalTestingManagerStarted e => e.linkId,
      IosInternalTestingManagerRefreshed e => e.linkId,
      _ => null,
    };

    if (linkId == null) return;

    emit(state.copyWith(
      loading: true,
      clearError: true,
      clearMessage: true,
    ));

    try {
      final IosInternalTestingAppSummary summary = await getSummaryUc(
        linkId: linkId,
      );

      emit(state.copyWith(
        loading: false,
        summary: summary,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }

  Future<void> _onSubmit(
    IosInternalTestingManagerSubmitted event,
    Emitter<IosInternalTestingManagerState> emit,
  ) async {
    emit(state.copyWith(
      submitting: true,
      clearError: true,
      clearMessage: true,
    ));

    try {
      final request = await createRequestUc(
        linkId: event.linkId,
        appleEmail: event.appleEmail,
        firstName: event.firstName,
        lastName: event.lastName,
      );

      final summary = await getSummaryUc(linkId: event.linkId);

      emit(state.copyWith(
        submitting: false,
        summary: summary,
        message: request.status,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }

  void _onClearMessage(
    IosInternalTestingManagerMessageCleared event,
    Emitter<IosInternalTestingManagerState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }

  void _onClearError(
    IosInternalTestingManagerErrorCleared event,
    Emitter<IosInternalTestingManagerState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}