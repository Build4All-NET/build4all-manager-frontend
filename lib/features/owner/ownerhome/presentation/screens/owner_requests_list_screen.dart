import 'package:build4all_manager/features/owner/ownerhome/presentation/widgets/request_card.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/data/repositories/owner_repository_impl.dart';
import '../../../common/data/services/owner_api.dart';
import '../../../common/domain/entities/app_request.dart';
import '../../../common/domain/usecases/get_my_requests_uc.dart';

class OwnerRequestsListScreen extends StatelessWidget {
  final int ownerId;
  final Dio dio;

  const OwnerRequestsListScreen({
    super.key,
    required this.ownerId,
    required this.dio,
  });

  @override
  Widget build(BuildContext context) {
    final repo = OwnerRepositoryImpl(OwnerApi(dio));
    final uc = GetMyRequestsUc(repo);

    return BlocProvider(
      create: (_) => _RequestsCubit(getMyRequests: uc)..load(ownerId),
      child: const _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.owner_home_recentRequests),
      ),
      body: BlocConsumer<_RequestsCubit, _RequestsState>(
        listenWhen: (p, c) =>
            p.error != c.error && (c.error?.isNotEmpty ?? false),
        listener: (context, s) {
          if (s.error != null && s.error!.trim().isNotEmpty) {
            AppToast.error(context, s.error!);
          }
        },
        builder: (context, s) {
          return RefreshIndicator(
            onRefresh: () => context.read<_RequestsCubit>().load(s.ownerId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                TextField(
                  onChanged: context.read<_RequestsCubit>().setQuery,
                  decoration: InputDecoration(
                    hintText: l10n.owner_home_search_hint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (s.loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  )
                else if (s.filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      l10n.owner_home_noRecent,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.7),
                      ),
                    ),
                  )
                else
                  ...s.filtered.map((r) => RequestCard(req: r)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestsCubit extends Cubit<_RequestsState> {
  final GetMyRequestsUc getMyRequests;

  _RequestsCubit({required this.getMyRequests})
      : super(const _RequestsState(ownerId: 0));

  Future<void> load(int ownerId) async {
    emit(state.copyWith(ownerId: ownerId, loading: true, error: null));
    try {
      final List<AppRequest> all = await getMyRequests();

      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(
        loading: false,
        all: all,
      ));
      _applyFilter();
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }

  void setQuery(String q) {
    emit(state.copyWith(query: q));
    _applyFilter();
  }

  void _applyFilter() {
    final q = state.query.trim().toLowerCase();
    if (q.isEmpty) {
      emit(state.copyWith(filtered: state.all));
      return;
    }

    final filtered = state.all.where((r) {
      return r.appName.toLowerCase().contains(q) ||
          (r.projectName ?? '').toLowerCase().contains(q) ||
          r.status.toLowerCase().contains(q);
    }).toList();

    emit(state.copyWith(filtered: filtered));
  }
}

class _RequestsState {
  final int ownerId;
  final bool loading;
  final String? error;

  final String query;
  final List<AppRequest> all;
  final List<AppRequest> filtered;

  const _RequestsState({
    required this.ownerId,
    this.loading = false,
    this.error,
    this.query = '',
    this.all = const [],
    this.filtered = const [],
  });

  _RequestsState copyWith({
    int? ownerId,
    bool? loading,
    String? error,
    String? query,
    List<AppRequest>? all,
    List<AppRequest>? filtered,
  }) {
    return _RequestsState(
      ownerId: ownerId ?? this.ownerId,
      loading: loading ?? this.loading,
      error: error,
      query: query ?? this.query,
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
    );
  }
}