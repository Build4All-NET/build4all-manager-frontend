import 'package:build4all_manager/features/superadmin/publish_admin/domain/entities/app_publish_request_admin.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_publish_requests.dart';
import 'publish_requests_event.dart';
import 'publish_requests_state.dart';

class PublishRequestsBloc
    extends Bloc<PublishRequestsEvent, PublishRequestsState> {
  final GetPublishRequests getRequests;

  PublishRequestsBloc({required this.getRequests})
      : super(PublishRequestsState.initial()) {
    on<PublishRequestsLoad>(_onLoad);
    on<PublishRequestsSearchChanged>(_onSearch);
    on<PublishRequestsRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
      PublishRequestsLoad e, Emitter<PublishRequestsState> emit) async {
    emit(state.copyWith(loading: true, status: e.status, error: null));

    try {
      final items = await getRequests(status: e.status);
      emit(state.copyWith(
        loading: false,
        all: items,
        filtered: _filter(items, state.query),
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  void _onSearch(
      PublishRequestsSearchChanged e, Emitter<PublishRequestsState> emit) {
    final q = e.query;
    emit(state.copyWith(
      query: q,
      filtered: _filter(state.all, q),
    ));
  }

  Future<void> _onRefresh(
      PublishRequestsRefresh e, Emitter<PublishRequestsState> emit) async {
    add(PublishRequestsLoad(state.status));
  }

  List<AppPublishRequestAdmin> _filter(
    List<AppPublishRequestAdmin> items,
    String q,
  ) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((x) {
      final name = (x.appName ?? '').toLowerCase();
      final aup = (x.aupId?.toString() ?? '');
      final store = x.store.toLowerCase();
      final platform = x.platform.toLowerCase();

      return name.contains(query) ||
          aup.contains(query) ||
          store.contains(query) ||
          platform.contains(query);
    }).toList();
  }
}