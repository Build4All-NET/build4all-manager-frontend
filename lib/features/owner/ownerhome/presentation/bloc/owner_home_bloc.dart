import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/owner_project.dart';
import '../../../common/domain/usecases/get_app_config_uc.dart';
import '../../../common/domain/usecases/get_my_apps_uc.dart';

import 'owner_home_event.dart';
import 'owner_home_state.dart';

class OwnerHomeBloc extends Bloc<OwnerHomeEvent, OwnerHomeState> {
  final GetAppConfigUc getAppConfig;
  final GetMyAppsUc getMyApps;

  OwnerHomeBloc({
    required this.getAppConfig,
    required this.getMyApps,
  }) : super(const OwnerHomeState()) {
    on<OwnerHomeStarted>(_onLoad);
    on<OwnerHomeRefreshed>(_onLoad);
  }

  Future<void> _onLoad(OwnerHomeEvent e, Emitter<OwnerHomeState> emit) async {
    emit(state.copyWith(
      loading: true,
      error: null,
      myApps: const [],
      availableKinds: const {},
      kindToProjectId: const {},
    ));

    try {
      // ✅ config (optional)
      AppConfig? cfg;
      try {
        cfg = await getAppConfig();
      } catch (_) {
        cfg = null;
      }

      // ✅ SAME SOURCE as My Apps screen
      final List<OwnerProject> apps = await getMyApps();

      // ✅ only ACTIVE apps unlock templates
      final activeApps = apps.where((p) {
        final s = p.status.toString().trim().toUpperCase();
        return s == 'ACTIVE';
      }).toList();

      final Map<String, int> kindMap = {
        for (final p in activeApps)
          p.projectName.toString().trim().toLowerCase(): p.projectId
      };

      final kinds = kindMap.keys.where((k) => k.isNotEmpty).toSet();

      emit(state.copyWith(
        loading: false,
        config: cfg,
        myApps: apps, // ✅ keep full list to show in UI
        availableKinds: kinds,
        kindToProjectId: kindMap,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: err.toString(),
        myApps: const [],
        availableKinds: const {},
        kindToProjectId: const {},
      ));
    }
  }
}