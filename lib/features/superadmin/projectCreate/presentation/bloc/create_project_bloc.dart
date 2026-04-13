import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_project_usecase.dart';
import 'create_project_event.dart';
import 'create_project_state.dart';

class CreateProjectBloc extends Bloc<CreateProjectEvent, CreateProjectState> {
  final CreateProjectUseCase usecase;
  final Future<String?> Function() tokenProvider;

  CreateProjectBloc({
    required this.usecase,
    required this.tokenProvider,
  }) : super(const CreateProjectInitial()) {
    on<CreateProjectSubmitted>(_onSubmit);
    on<CreateProjectReset>((e, emit) => emit(const CreateProjectInitial()));
  }

  Future<void> _onSubmit(
    CreateProjectSubmitted e,
    Emitter<CreateProjectState> emit,
  ) async {
    emit(const CreateProjectLoading());

    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      emit(const CreateProjectFailure("Unauthorized"));
      return;
    }

    try {
      final project = await usecase(
        token: token,
        projectName: e.projectName,
        description: e.description,
        active: e.active,
        projectType: e.projectType,
      );

      emit(CreateProjectSuccess(project));
    } catch (err) {
      emit(CreateProjectFailure(err.toString()));
    }
  }
}