import '../../../publish_admin/domain/entities/app_publish_request_admin.dart';

class PublishRequestsState {
  final bool loading;
  final String status;
  final String query;
  final List<AppPublishRequestAdmin> all;
  final List<AppPublishRequestAdmin> filtered;
  final String? error;

  const PublishRequestsState({
    required this.loading,
    required this.status,
    required this.query,
    required this.all,
    required this.filtered,
    this.error,
  });

  factory PublishRequestsState.initial() => const PublishRequestsState(
        loading: false,
        status: 'SUBMITTED',
        query: '',
        all: [],
        filtered: [],
        error: null,
      );

  PublishRequestsState copyWith({
    bool? loading,
    String? status,
    String? query,
    List<AppPublishRequestAdmin>? all,
    List<AppPublishRequestAdmin>? filtered,
    String? error,
  }) {
    return PublishRequestsState(
      loading: loading ?? this.loading,
      status: status ?? this.status,
      query: query ?? this.query,
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      error: error,
    );
  }
}
