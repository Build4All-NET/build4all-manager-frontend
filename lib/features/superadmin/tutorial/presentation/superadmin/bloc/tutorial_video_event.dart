abstract class TutorialVideoEvent {
  const TutorialVideoEvent();
}

class TutorialVideoStarted extends TutorialVideoEvent {
  const TutorialVideoStarted();
}

class TutorialVideoRefreshRequested extends TutorialVideoEvent {
  const TutorialVideoRefreshRequested();
}

class TutorialVideoUploadRequested extends TutorialVideoEvent {
  final String filePath;
  final String fileName;
  const TutorialVideoUploadRequested({
    required this.filePath,
    required this.fileName,
  });
}

class TutorialVideoClearUi extends TutorialVideoEvent {
  const TutorialVideoClearUi();
}