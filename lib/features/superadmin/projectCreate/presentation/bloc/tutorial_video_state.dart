class TutorialVideoState {
  final bool loading;
  final bool uploading;
  final double progress; // 0..1
  final String? videoPath; // can be /uploads/... OR full URL
  final String? pickedFileName;
  final String? error;
  final String? message;

  const TutorialVideoState({
    required this.loading,
    required this.uploading,
    required this.progress,
    this.videoPath,
    this.pickedFileName,
    this.error,
    this.message,
  });

  factory TutorialVideoState.initial() => const TutorialVideoState(
        loading: true,
        uploading: false,
        progress: 0.0,
        videoPath: null,
        pickedFileName: null,
        error: null,
        message: null,
      );

  TutorialVideoState copyWith({
    bool? loading,
    bool? uploading,
    double? progress,
    String? videoPath,
    String? pickedFileName,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TutorialVideoState(
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      progress: progress ?? this.progress,
      videoPath: videoPath ?? this.videoPath,
      pickedFileName: pickedFileName ?? this.pickedFileName,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}