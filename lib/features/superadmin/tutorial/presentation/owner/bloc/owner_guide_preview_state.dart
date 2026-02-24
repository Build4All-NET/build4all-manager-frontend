class OwnerGuidePreviewState {
  final bool loading;
  final String? videoPath; // /uploads/... or full URL
  final String? error;

  const OwnerGuidePreviewState({
    required this.loading,
    this.videoPath,
    this.error,
  });

  factory OwnerGuidePreviewState.initial() => const OwnerGuidePreviewState(
        loading: true,
        videoPath: null,
        error: null,
      );

  OwnerGuidePreviewState copyWith({
    bool? loading,
    String? videoPath,
    String? error,
    bool clearError = false,
  }) {
    return OwnerGuidePreviewState(
      loading: loading ?? this.loading,
      videoPath: videoPath ?? this.videoPath,
      error: clearError ? null : (error ?? this.error),
    );
  }
}