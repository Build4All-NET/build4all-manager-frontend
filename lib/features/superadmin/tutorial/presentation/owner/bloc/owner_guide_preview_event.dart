abstract class OwnerGuidePreviewEvent {
  const OwnerGuidePreviewEvent();
}

class OwnerGuidePreviewStarted extends OwnerGuidePreviewEvent {
  const OwnerGuidePreviewStarted();
}

class OwnerGuidePreviewRefreshRequested extends OwnerGuidePreviewEvent {
  const OwnerGuidePreviewRefreshRequested();
}

class OwnerGuidePreviewClearUi extends OwnerGuidePreviewEvent {
  const OwnerGuidePreviewClearUi();
}