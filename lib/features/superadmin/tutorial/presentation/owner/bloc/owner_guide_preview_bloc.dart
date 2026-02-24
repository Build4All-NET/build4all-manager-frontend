import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_owner_guide_video.dart';
import 'owner_guide_preview_event.dart';
import 'owner_guide_preview_state.dart';

class OwnerGuidePreviewBloc
    extends Bloc<OwnerGuidePreviewEvent, OwnerGuidePreviewState> {
  final GetOwnerGuideVideo getOwnerGuide;
  final Future<String?> Function()? tokenProvider;

  OwnerGuidePreviewBloc({
    required this.getOwnerGuide,
    this.tokenProvider,
  }) : super(OwnerGuidePreviewState.initial()) {
    on<OwnerGuidePreviewStarted>(_onLoad);
    on<OwnerGuidePreviewRefreshRequested>(_onLoad);
    on<OwnerGuidePreviewClearUi>(
      (e, emit) => emit(state.copyWith(clearError: true)),
    );
  }

  Future<void> _onLoad(
    OwnerGuidePreviewEvent event,
    Emitter<OwnerGuidePreviewState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final token = tokenProvider == null ? null : await tokenProvider!();
      final path = await getOwnerGuide(token: token);

      emit(state.copyWith(
        loading: false,
        videoPath: (path == null || path.trim().isEmpty) ? null : path.trim(),
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: err.toString(),
      ));
    }
  }
}