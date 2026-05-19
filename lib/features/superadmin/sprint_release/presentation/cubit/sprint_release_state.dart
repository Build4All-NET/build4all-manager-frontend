abstract class SprintReleaseState {}

class SprintReleaseIdle extends SprintReleaseState {}

class SprintReleaseLoading extends SprintReleaseState {}

class SprintReleaseSuccess extends SprintReleaseState {
  final String sprintName;
  SprintReleaseSuccess(this.sprintName);
}

class SprintReleaseError extends SprintReleaseState {
  final String message;
  SprintReleaseError(this.message);
}
