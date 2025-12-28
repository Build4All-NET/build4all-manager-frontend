import '../../domain/entities/project.dart';

abstract class CreateProjectState {
  const CreateProjectState();
}

class CreateProjectInitial extends CreateProjectState {
  const CreateProjectInitial();
}

class CreateProjectLoading extends CreateProjectState {
  const CreateProjectLoading();
}

class CreateProjectSuccess extends CreateProjectState {
  final Project project;
  const CreateProjectSuccess(this.project);
}

class CreateProjectFailure extends CreateProjectState {
  final String message;
  const CreateProjectFailure(this.message);
}
