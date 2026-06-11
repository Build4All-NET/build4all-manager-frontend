class TutorialVideoState {
  final bool loading;
  final bool uploading;
  final bool savingUrl;
  final double progress;
  final String? videoPath;
  final String? pickedFileName;
  final String? error;
  final String? message;

  const TutorialVideoState({
    required this.loading,
    required this.uploading,
    required this.savingUrl,
    required this.progress,
    this.videoPath,
    this.pickedFileName,
    this.error,
    this.message,
  });

  factory TutorialVideoState.initial() => const TutorialVideoState(
        loading: true,
        uploading: false,
        savingUrl: false,
        progress: 0.0,
        videoPath: null,
        pickedFileName: null,
        error: null,
        message: null,
      );

  TutorialVideoState copyWith({
    bool? loading,
    bool? uploading,
    bool? savingUrl,
    double? progress,
    String? videoPath,
    String? pickedFileName,
    String? error,
    String? message,
    bool clearVideoPath = false,
    bool clearPickedFileName = false,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TutorialVideoState(
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      savingUrl: savingUrl ?? this.savingUrl,
      progress: progress ?? this.progress,
      videoPath: clearVideoPath ? null : (videoPath ?? this.videoPath),
      pickedFileName:
          clearPickedFileName ? null : (pickedFileName ?? this.pickedFileName),
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}