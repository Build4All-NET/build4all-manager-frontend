import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/utils/ApiErrorHandler.dart';
import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/owner_project.dart';
import '../../../common/domain/usecases/get_app_config_uc.dart';
import '../../../common/domain/usecases/get_my_apps_uc.dart';

import '../../domain/entities/backend_project.dart';
import '../../domain/usecases/get_platform_projects_uc.dart';

import 'owner_home_event.dart';
import 'owner_home_state.dart';

class OwnerHomeBloc extends Bloc<OwnerHomeEvent, OwnerHomeState> {
  final GetAppConfigUc getAppConfig;
  final GetMyAppsUc getMyApps;
  final GetPlatformProjectsUc getPlatformProjects;

  OwnerHomeBloc({
    required this.getAppConfig,
    required this.getMyApps,
    required this.getPlatformProjects,
  }) : super(const OwnerHomeState()) {
    on<OwnerHomeStarted>(_onLoad);
    on<OwnerHomeRefreshed>(_onLoad);
  }

  String? _mapProjectToKind(BackendProject p) {
    final type = (p.projectType ?? '').trim().toUpperCase();

    if (type.isNotEmpty) {
      switch (type) {
        case 'ECOMMERCE':
        case 'E_COMMERCE':
        case 'SHOP':
          return 'ecommerce';
        case 'ACTIVITIES':
        case 'ACTIVITY':
          return 'activities';
        case 'GYM':
        case 'FITNESS':
          return 'gym';
        case 'SERVICES':
        case 'SERVICE':
          return 'services';
      }
    }

    final raw = '${p.name} ${p.description}'.toLowerCase();
    if (raw.contains('ecom') || raw.contains('shop')) return 'ecommerce';
    if (raw.contains('activ')) return 'activities';
    if (raw.contains('gym') || raw.contains('fitness')) return 'gym';
    if (raw.contains('service')) return 'services';

    return null;
  }

  Future<void> _onLoad(OwnerHomeEvent e, Emitter<OwnerHomeState> emit) async {
    emit(state.copyWith(
      loading: true,
      error: null,
      myApps: const [],
      platformProjects: const [],
      availableKinds: const {},
      kindToProjectId: const {},
    ));

    try {
      AppConfig? cfg;
      try {
        cfg = await getAppConfig();
      } catch (_) {
        cfg = null;
      }

      final results = await Future.wait([
        getMyApps(),
        getPlatformProjects(),
      ]);

      final List<OwnerProject> apps = results[0] as List<OwnerProject>;
      final List<BackendProject> projects = results[1] as List<BackendProject>;

      final activeProjects = projects.where((p) => p.active == true).toList();

      final Map<String, int> kindToProjectId = {};
      for (final p in activeProjects) {
        final k = _mapProjectToKind(p);
        if (k == null) continue;
        kindToProjectId.putIfAbsent(k, () => p.id);
      }

      emit(state.copyWith(
        loading: false,
        config: cfg,
        myApps: apps,
        platformProjects: projects,
        availableKinds: kindToProjectId.keys.toSet(),
        kindToProjectId: kindToProjectId,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
        myApps: const [],
        platformProjects: const [],
        availableKinds: const {},
        kindToProjectId: const {},
      ));
    }
  }
}