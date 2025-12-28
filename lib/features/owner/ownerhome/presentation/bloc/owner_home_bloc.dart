// lib/features/owner/ownerhome/presentation/bloc/owner_home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/entities/app_config.dart';
import '../../../common/domain/entities/app_request.dart';
import '../../../common/domain/usecases/get_app_config_uc.dart';
import '../../../common/domain/usecases/get_my_requests_uc.dart';
import '../../domain/usecases/get_available_kinds_from_active_uc.dart';

import 'owner_home_event.dart';
import 'owner_home_state.dart';

class OwnerHomeBloc extends Bloc<OwnerHomeEvent, OwnerHomeState> {
  final GetMyRequestsUc getMyRequests;
  final GetAppConfigUc getAppConfig;
  final GetAvailableKindsFromActiveUc getAvailableKinds;

  OwnerHomeBloc({
    required this.getMyRequests,
    required this.getAppConfig,
    required this.getAvailableKinds,
  }) : super(const OwnerHomeState()) {
    on<OwnerHomeStarted>(_onLoad);
    on<OwnerHomeRefreshed>(_onLoad);
  }

  Future<void> _onLoad(OwnerHomeEvent e, Emitter<OwnerHomeState> emit) async {
    final ownerId =
        (e is OwnerHomeStarted) ? e.ownerId : (e as OwnerHomeRefreshed).ownerId;

    // ✅ reset to disable all cards immediately
    emit(state.copyWith(
      loading: true,
      error: null,
      availableKinds: const {},
      kindToProjectId: const {},
    ));

    try {
      // ✅ requests
      final List<AppRequest> reqs = await getMyRequests(ownerId);
      reqs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // ✅ config (optional)
      AppConfig? cfg;
      try {
        cfg = await getAppConfig();
      } catch (_) {
        cfg = null;
      }

      // ✅ projects kinds map (main)
      Map<String, int> kindMap;
      try {
        kindMap = await getAvailableKinds(); // Map<String,int>
      } catch (_) {
        // if backend fails => keep disabled
        kindMap = const {};
      }

      final kinds = kindMap.keys
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      emit(state.copyWith(
        loading: false,
        recent: reqs.take(5).toList(),
        config: cfg,
        availableKinds: kinds,
        kindToProjectId: kindMap,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: err.toString(),
        availableKinds: const {},
        kindToProjectId: const {},
      ));
    }
  }
}
