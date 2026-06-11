import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/get_owner_guide_video.dart';
import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/upload_owner_guide_video.dart';
import 'package:build4all_manager/features/superadmin/tutorial/domain/usecases/save_owner_guide_url.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tutorial_video_event.dart';
import 'tutorial_video_state.dart';

class TutorialVideoBloc extends Bloc<TutorialVideoEvent, TutorialVideoState> {
  final GetOwnerGuideVideo getOwnerGuide;
  final UploadOwnerGuideVideo uploadOwnerGuide;
  final SaveOwnerGuideUrl saveOwnerGuideUrl;
  final Future<String?> Function() tokenProvider;

  TutorialVideoBloc({
    required this.getOwnerGuide,
    required this.uploadOwnerGuide,
    required this.saveOwnerGuideUrl,
    required this.tokenProvider,
  }) : super(TutorialVideoState.initial()) {
    on<TutorialVideoStarted>(_onLoad);
    on<TutorialVideoRefreshRequested>(_onLoad);
    on<TutorialVideoUploadRequested>(_onUpload);
    on<TutorialVideoUrlSaveRequested>(_onSaveUrl);

    on<_TutorialVideoProgressInternal>((e, emit) {
      emit(state.copyWith(progress: e.progress));
    });

    on<TutorialVideoClearUi>(
      (e, emit) => emit(
        state.copyWith(
          clearError: true,
          clearMessage: true,
        ),
      ),
    );
  }

  Future<String> _requireToken() async {
    final token = await tokenProvider();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Unauthorized');
    }

    return token.trim();
  }

  Future<void> _onLoad(
    TutorialVideoEvent e,
    Emitter<TutorialVideoState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final token = await tokenProvider();
      final path = await getOwnerGuide(token: token);

      emit(
        state.copyWith(
          loading: false,
          videoPath: (path == null || path.trim().isEmpty)
              ? null
              : path.trim(),
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: ApiErrorHandler.message(err),
        ),
      );
    }
  }

  Future<void> _onSaveUrl(
    TutorialVideoUrlSaveRequested e,
    Emitter<TutorialVideoState> emit,
  ) async {
    final url = e.videoUrl.trim();

    if (url.isEmpty) {
      emit(
        state.copyWith(
          error: 'Video URL is required',
        ),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      emit(
        state.copyWith(
          error: 'Video URL must start with http:// or https://',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savingUrl: true,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final token = await _requireToken();

      final newPath = await saveOwnerGuideUrl(
        token: token,
        videoUrl: url,
      );

      emit(
        state.copyWith(
          savingUrl: false,
          videoPath: (newPath == null || newPath.trim().isEmpty)
              ? null
              : newPath.trim(),
          clearPickedFileName: true,
          message: 'Tutorial video link saved.',
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          savingUrl: false,
          error: ApiErrorHandler.message(err),
        ),
      );
    }
  }

  Future<void> _onUpload(
    TutorialVideoUploadRequested e,
    Emitter<TutorialVideoState> emit,
  ) async {
    emit(
      state.copyWith(
        uploading: true,
        progress: 0.0,
        pickedFileName: e.fileName,
        clearError: true,
        clearMessage: true,
      ),
    );

    try {
      final token = await _requireToken();

      final newPath = await uploadOwnerGuide(
        token: token,
        filePath: e.filePath,
        onSendProgress: (sent, total) {
          final p = (total <= 0) ? 0.0 : (sent / total).clamp(0.0, 1.0);

          if (!isClosed) {
            add(_TutorialVideoProgressInternal(p));
          }
        },
      );

      emit(
        state.copyWith(
          uploading: false,
          progress: 1.0,
          videoPath: (newPath == null || newPath.trim().isEmpty)
              ? null
              : newPath.trim(),
          message: 'Tutorial video uploaded.',
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          uploading: false,
          error: ApiErrorHandler.message(err),
        ),
      );
    }
  }
}

class _TutorialVideoProgressInternal extends TutorialVideoEvent {
  final double progress;

  const _TutorialVideoProgressInternal(this.progress);
}