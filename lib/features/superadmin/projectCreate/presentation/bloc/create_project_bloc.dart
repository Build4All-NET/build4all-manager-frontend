import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

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
    if (token == null || token.trim().isEmpty) {
      emit(const CreateProjectFailure("Unauthorized"));
      return;
    }

    try {
      String? _clean(String? s) =>
          (s == null || s.trim().isEmpty) ? null : s.trim();

      final project = await usecase(
        token: token,
        projectName: e.projectName.trim(),
        description: _clean(e.description),
        active: e.active,
        projectType: e.projectType.trim(),
        displayTitle: _clean(e.displayTitle),
        displayDescription: _clean(e.displayDescription),
        iconName: _clean(e.iconName),
        cardColor: _clean(e.cardColor),
        displayOrder: e.displayOrder,
      );

      emit(CreateProjectSuccess(project));
    } catch (err) {
      emit(CreateProjectFailure(ApiErrorHandler.message(err)));
    }
  }
}