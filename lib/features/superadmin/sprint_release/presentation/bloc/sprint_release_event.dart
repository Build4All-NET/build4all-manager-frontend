import 'package:equatable/equatable.dart';

abstract class SprintReleaseEvent extends Equatable {
  const SprintReleaseEvent();
  @override
  List<Object?> get props => [];
}

class SprintReleaseLoadPat extends SprintReleaseEvent {}

class SprintReleaseSavePat extends SprintReleaseEvent {
  final String pat;
  const SprintReleaseSavePat(this.pat);
  @override
  List<Object?> get props => [pat];
}

class SprintReleaseClearPat extends SprintReleaseEvent {}

class SprintReleaseTrigger extends SprintReleaseEvent {
  final String pat;
  final String sprintName;
  const SprintReleaseTrigger({required this.pat, required this.sprintName});
  @override
  List<Object?> get props => [pat, sprintName];
}
