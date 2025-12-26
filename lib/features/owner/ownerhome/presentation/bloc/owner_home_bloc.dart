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

    // ✅ IMPORTANT: reset kinds FIRST so all cards become inactive immediately
    emit(state.copyWith(
      loading: true,
      error: null,
      availableKinds: const {}, // 👈 key fix
    ));

    try {
      // ✅ Fetch requests
      final List<AppRequest> reqs = await getMyRequests(ownerId);
      reqs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // ✅ Fetch config (optional)
      AppConfig? cfg;
      try {
        cfg = await getAppConfig();
      } catch (_) {
        cfg = null;
      }

      // ✅ Fetch kinds (main)
      Set<String> kinds = const {};
      try {
        final raw = await getAvailableKinds(); // expects Set<String>
        kinds = _normalizeKinds(raw);
      } catch (_) {
        // ✅ if backend fails => KEEP EMPTY (everything inactive)
        kinds = const {};
      }

      emit(state.copyWith(
        loading: false,
        recent: reqs.take(5).toList(),
        config: cfg,
        availableKinds: kinds,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: err.toString(),
        availableKinds: const {}, // stay inactive on error
      ));
    }
  }

  // ✅ Normalize so contains works even if backend returns "ECOMMERCE"
  Set<String> _normalizeKinds(Set<String> kinds) {
    return kinds
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}
