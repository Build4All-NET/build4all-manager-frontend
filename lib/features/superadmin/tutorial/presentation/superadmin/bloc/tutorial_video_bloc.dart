import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/get_owner_guide_video.dart';
import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/upload_owner_guide_video.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tutorial_video_event.dart';
import 'tutorial_video_state.dart';

class TutorialVideoBloc extends Bloc<TutorialVideoEvent, TutorialVideoState> {
  final GetOwnerGuideVideo getOwnerGuide;
  final UploadOwnerGuideVideo uploadOwnerGuide;
  final Future<String?> Function() tokenProvider;

  TutorialVideoBloc({
    required this.getOwnerGuide,
    required this.uploadOwnerGuide,
    required this.tokenProvider,
  }) : super(TutorialVideoState.initial()) {
    on<TutorialVideoStarted>(_onLoad);
    on<TutorialVideoRefreshRequested>(_onLoad);
    on<TutorialVideoUploadRequested>(_onUpload);

    // ✅ FIX: handle progress updates
    on<_TutorialVideoProgressInternal>((e, emit) {
      emit(state.copyWith(progress: e.progress));
    });

    on<TutorialVideoClearUi>(
      (e, emit) => emit(state.copyWith(clearError: true, clearMessage: true)),
    );
  }

  Future<void> _onLoad(
    TutorialVideoEvent e,
    Emitter<TutorialVideoState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));

    try {
      final token = await tokenProvider(); // may be null
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

  Future<void> _onUpload(
    TutorialVideoUploadRequested e,
    Emitter<TutorialVideoState> emit,
  ) async {
    emit(state.copyWith(
      uploading: true,
      progress: 0.0,
      pickedFileName: e.fileName,
      clearError: true,
      clearMessage: true,
    ));

    final token = await tokenProvider();
    if (token == null || token.trim().isEmpty) {
      emit(state.copyWith(
        uploading: false,
        error: "Unauthorized",
      ));
      return;
    }

    try {
      final newPath = await uploadOwnerGuide(
        token: token,
        filePath: e.filePath,
        onSendProgress: (sent, total) {
          final p = (total <= 0) ? 0.0 : (sent / total).clamp(0.0, 1.0);
          if (!isClosed) add(_TutorialVideoProgressInternal(p));
        },
      );

      emit(state.copyWith(
        uploading: false,
        progress: 1.0,
        videoPath: (newPath == null || newPath.trim().isEmpty)
            ? null
            : newPath.trim(),
        message: "Tutorial video uploaded.",
      ));
    } catch (err) {
      emit(state.copyWith(
        uploading: false,
        error: err.toString(),
      ));
    }
  }
}

class _TutorialVideoProgressInternal extends TutorialVideoEvent {
  final double progress;
  const _TutorialVideoProgressInternal(this.progress);
}