import '../../data/github_dispatch_service.dart';

abstract class SprintReleaseState {}

class SprintReleaseIdle extends SprintReleaseState {}

class SprintReleaseLoading extends SprintReleaseState {}

class SprintReleaseSuccess extends SprintReleaseState {
  final WorkflowJob job;
  SprintReleaseSuccess(this.job);
}

class SprintReleaseError extends SprintReleaseState {
  final String message;
  SprintReleaseError(this.message);
}
