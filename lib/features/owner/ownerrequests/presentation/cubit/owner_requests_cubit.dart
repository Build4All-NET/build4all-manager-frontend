import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/i_owner_requests_repository.dart';
import '../../data/services/owner_requests_api.dart';
import '../../utils/slug.dart';
import '../../../common/domain/entities/app_request.dart';
import 'owner_requests_state.dart';

class OwnerRequestsCubit extends Cubit<OwnerRequestsState> {
  final IOwnerRequestsRepository repo;
  final int ownerId;

  OwnerRequestApi? _api;
  void setConcreteApi(OwnerRequestApi api) => _api = api;

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
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void selectProject(Project? p) => emit(state.copyWith(selected: p));
  void setAppName(String v) => emit(state.copyWith(appName: v));

  void setLogoUrl(String? v) =>
      emit(state.copyWith(logoUrl: v, logoFilePath: null));

  void setThemeId(int? id) => emit(state.copyWith(selectedThemeId: id));

  // ✅ new setters
  void setCurrencyId(int? id) => emit(state.copyWith(currencyId: id));
  void setApiBaseUrlOverride(String? v) => emit(
        state.copyWith(apiBaseUrlOverride: (v ?? '').trim().isEmpty ? null : v),
      );
  void setNavJson(String? v) => emit(state.copyWith(navJson: v));
  void setHomeJson(String? v) => emit(state.copyWith(homeJson: v));
  void setEnabledFeaturesJson(String? v) =>
      emit(state.copyWith(enabledFeaturesJson: v));
  void setBrandingJson(String? v) => emit(state.copyWith(brandingJson: v));

  Future<void> pickLogoFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    emit(state.copyWith(logoFilePath: path, logoUrl: null));
  }

  Future<void> submitAutoOneShot() async {
    if (_api == null) {
      emit(state.copyWith(error: 'API not wired'));
      return;
    }
    if (state.selected == null) {
      emit(state.copyWith(error: '_ERR_NO_PROJECT_'));
      return;
    }
    if (state.appName.trim().isEmpty) {
      emit(state.copyWith(error: '_ERR_NO_APPNAME_'));
      return;
    }

    final slug = slugify(state.appName);

    emit(state.copyWith(
      submitting: true,
      error: null,
      lastCreated: null,
      builtApkUrl: null,
      builtAt: null,
    ));

    try {
      final fields = <String, dynamic>{
        'projectId': state.selected!.id,
        'appName': state.appName.trim(),
        'slug': slug,
        if (state.selectedThemeId != null) 'themeId': state.selectedThemeId,

        // ✅ new fields
        if (state.currencyId != null) 'currencyId': state.currencyId,
        if ((state.apiBaseUrlOverride ?? '').trim().isNotEmpty)
          'apiBaseUrlOverride': state.apiBaseUrlOverride!.trim(),

        if ((state.navJson ?? '').trim().isNotEmpty) 'navJson': state.navJson,
        if ((state.homeJson ?? '').trim().isNotEmpty)
          'homeJson': state.homeJson,
        if ((state.enabledFeaturesJson ?? '').trim().isNotEmpty)
          'enabledFeaturesJson': state.enabledFeaturesJson,
        if ((state.brandingJson ?? '').trim().isNotEmpty)
          'brandingJson': state.brandingJson,
      };

      if ((state.logoFilePath ?? '').isNotEmpty) {
        fields['file'] = await MultipartFile.fromFile(
          state.logoFilePath!,
          filename: 'logo.png',
        );
      } else if ((state.logoUrl ?? '').isNotEmpty) {
        // works only if backend accepts logoUrl param (optional)
        fields['logoUrl'] = state.logoUrl;
      }

      final form = FormData.fromMap(fields);

      final res = await _api!.dio.post(
        '/owner/app-requests/auto',
        queryParameters: {'ownerId': ownerId},
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = (res.data as Map).map((k, v) => MapEntry(k.toString(), v));

      final returnedSlug = (data['slug'] ?? '').toString();
      final returnedStatus = (data['status'] ?? '').toString();
      final apkUrl = (data['apkUrl'] ?? '').toString();
      final projectId = int.tryParse((data['projectId'] ?? '0').toString()) ??
          state.selected!.id;

      final reqs = await repo.getMyRequests(ownerId);

      final created = AppRequest(
        id: 0,
        ownerId: ownerId,
        projectId: projectId,
        appName: state.appName.trim(),
        status: (returnedStatus.isEmpty)
            ? 'APPROVED'
            : returnedStatus.toUpperCase(),
        createdAt: DateTime.now(),
        slug: (returnedSlug.isEmpty) ? slug : returnedSlug,
        apkUrl: apkUrl.isEmpty ? null : apkUrl,
      );

      emit(state.copyWith(
        submitting: false,
        myRequests: reqs,
        lastCreated: created,
        builtApkUrl: apkUrl.isEmpty ? null : apkUrl,

        // reset form
        selected: null,
        appName: '',
        logoUrl: null,
        logoFilePath: null,
        selectedThemeId: null,
        currencyId: null,
        apiBaseUrlOverride: null,
        navJson: null,
        homeJson: null,
        enabledFeaturesJson: null,
        brandingJson: null,
      ));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
