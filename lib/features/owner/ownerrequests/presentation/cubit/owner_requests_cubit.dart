import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/i_owner_requests_repository.dart';
import 'owner_requests_state.dart';

class OwnerRequestsCubit extends Cubit<OwnerRequestsState> {
  final IOwnerRequestsRepository repo;
  final int ownerId;

  OwnerRequestsCubit({required this.repo, required this.ownerId})
      : super(const OwnerRequestsState.initial());

  Future<void> init() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final projects = await repo.getAvailableProjects();
      final reqs = await repo.getMyRequests(ownerId);
      final themes = await repo.getThemes();
      emit(state.copyWith(
        loading: false,
        projects: projects,
        myRequests: reqs,
        themes: themes,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }

  void selectProject(Project? p) => emit(state.copyWith(selectedProject: p));
  void setAppName(String v) => emit(state.copyWith(appName: v));

  void setThemeId(int? id) => emit(state.copyWith(selectedThemeId: id));
  void setCurrencyId(int? id) => emit(state.copyWith(currencyId: id));

  void setNotes(String v) => emit(state.copyWith(notes: v));
  void setPrimary(String v) => emit(state.copyWith(primaryColor: v));
  void setSecondary(String v) => emit(state.copyWith(secondaryColor: v));
  void setBg(String v) => emit(state.copyWith(backgroundColor: v));
  void setOnBg(String v) => emit(state.copyWith(onBackgroundColor: v));
  void setErr(String v) => emit(state.copyWith(errorColor: v));

  void setNavJson(String v) => emit(state.copyWith(navJson: v));
  void setHomeJson(String v) => emit(state.copyWith(homeJson: v));
  void setFeaturesJson(String v) =>
      emit(state.copyWith(enabledFeaturesJson: v));
  void setBrandingJson(String v) => emit(state.copyWith(brandingJson: v));

  void setApiBaseOverride(String? v) => emit(
        state.copyWith(apiBaseUrlOverride: (v ?? '').trim().isEmpty ? null : v),
      );

  Future<void> pickLogoFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    emit(state.copyWith(logoFilePath: path));
  }

  void clearLogo() => emit(state.copyWith(logoFilePath: null));

  Future<void> submitManual() async {
    if (state.selectedProject == null) {
      emit(state.copyWith(error: 'Pick a project first.'));
      return;
    }
    if (state.appName.trim().isEmpty) {
      emit(state.copyWith(error: 'App name is required.'));
      return;
    }
    if (state.currencyId == null) {
      emit(state.copyWith(error: 'Currency is required.'));
      return;
    }

    emit(state.copyWith(submitting: true, error: null, lastCreated: null));
    try {
      final created = await repo.createAppRequestManual(
        ownerId: ownerId,
        projectId: state.selectedProject!.id,
        appName: state.appName.trim(),
        currencyId: state.currencyId!,
        notes: state.notes,
        primaryColor: state.primaryColor,
        secondaryColor: state.secondaryColor,
        backgroundColor: state.backgroundColor,
        onBackgroundColor: state.onBackgroundColor,
        errorColor: state.errorColor,
        navJson: state.navJson,
        homeJson: state.homeJson,
        enabledFeaturesJson: state.enabledFeaturesJson,
        brandingJson: state.brandingJson,
        apiBaseUrlOverride: state.apiBaseUrlOverride,
        themeId: state.selectedThemeId,
        logoFilePath: state.logoFilePath,
      );

      final reqs = await repo.getMyRequests(ownerId);

      emit(state.copyWith(
        submitting: false,
        myRequests: reqs,
        lastCreated: created,
        appName: '',
        notes: '',
        logoFilePath: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }
}