import 'package:equatable/equatable.dart';

import '../../data/models/super_admin_ios_internal_testing_request_model.dart';

enum SuperAdminIosInternalTestingNotice {
  processSuccess,
  syncSuccess,
  noSyncableVisible,
  syncAllFinished,
}

class SuperAdminIosInternalTestingState extends Equatable {
  final bool loading;
  final bool acting;
  final int? actionRequestId;

  final List<SuperAdminIosInternalTestingRequestModel> requests;

  final String searchQuery;
  final String selectedStatus;

  final String? error;

  final SuperAdminIosInternalTestingNotice? notice;
  final int syncAllUpdatedCount;

  const SuperAdminIosInternalTestingState({
    this.loading = false,
    this.acting = false,
    this.actionRequestId,
    this.requests = const [],
    this.searchQuery = '',
    this.selectedStatus = 'ALL',
    this.error,
    this.notice,
    this.syncAllUpdatedCount = 0,
  });

  List<SuperAdminIosInternalTestingRequestModel> get filteredRequests {
    final q = searchQuery.trim().toLowerCase();

    return requests.where((r) {
      final statusOk = selectedStatus == 'ALL'
          ? true
          : r.status.trim().toUpperCase() == selectedStatus.trim().toUpperCase();

      if (!statusOk) return false;
      if (q.isEmpty) return true;

      final haystack = [
        r.appNameSnapshot,
        r.bundleIdSnapshot,
        r.appleEmail,
        r.firstName,
        r.lastName,
        r.status,
        r.lastError ?? '',
        r.id.toString(),
        r.ownerProjectLinkId.toString(),
      ].join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList();
  }

  int countByStatus(String status) {
    final target = status.trim().toUpperCase();
    return requests.where((r) => r.status.trim().toUpperCase() == target).length;
  }

  int get totalCount => requests.length;
  int get readyCount => countByStatus('READY');
  int get waitingCount => countByStatus('WAITING_OWNER_ACCEPTANCE');
  int get failedCount => countByStatus('FAILED');
  int get addingCount => countByStatus('ADDING_TO_INTERNAL_TESTING');
  int get processingCount => countByStatus('PROCESSING');

  SuperAdminIosInternalTestingState copyWith({
    bool? loading,
    bool? acting,
    int? actionRequestId,
    bool clearActionRequestId = false,
    List<SuperAdminIosInternalTestingRequestModel>? requests,
    String? searchQuery,
    String? selectedStatus,
    String? error,
    bool clearError = false,
    SuperAdminIosInternalTestingNotice? notice,
    bool clearNotice = false,
    int? syncAllUpdatedCount,
  }) {
    return SuperAdminIosInternalTestingState(
      loading: loading ?? this.loading,
      acting: acting ?? this.acting,
      actionRequestId: clearActionRequestId
          ? null
          : (actionRequestId ?? this.actionRequestId),
      requests: requests ?? this.requests,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      syncAllUpdatedCount: syncAllUpdatedCount ?? this.syncAllUpdatedCount,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        acting,
        actionRequestId,
        requests,
        searchQuery,
        selectedStatus,
        error,
        notice,
        syncAllUpdatedCount,
      ];
}