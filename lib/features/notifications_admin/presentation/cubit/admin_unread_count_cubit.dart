import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';
import 'package:flutter/widgets.dart';

class AdminUnreadCountState {
  final int count;
  final bool loading;

  const AdminUnreadCountState({
    required this.count,
    required this.loading,
  });

  factory AdminUnreadCountState.initial() {
    return const AdminUnreadCountState(
      count: 0,
      loading: false,
    );
  }

  AdminUnreadCountState copyWith({
    int? count,
    bool? loading,
  }) {
    return AdminUnreadCountState(
      count: count ?? this.count,
      loading: loading ?? this.loading,
    );
  }
}

class AdminUnreadCountCubit extends Cubit<AdminUnreadCountState>
    with WidgetsBindingObserver {
  final AdminNotificationsApi api;
  Timer? _timer;
  bool _busy = false;
  bool _disposed = false;

  AdminUnreadCountCubit(this.api) : super(AdminUnreadCountState.initial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> start() async {
    if (_disposed || isClosed) return;

    await refresh();

    if (_disposed || isClosed) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_disposed || isClosed) return;
      refresh(silent: true);
    });
  }

  Future<void> refresh({bool silent = false}) async {
    if (_disposed || isClosed || _busy) return;
    _busy = true;

    if (!silent) {
      if (_disposed || isClosed) {
        _busy = false;
        return;
      }
      emit(state.copyWith(loading: true));
    }

    try {
      final count = await api.getUnreadCount();

      if (_disposed || isClosed) return;

      emit(state.copyWith(
        count: count,
        loading: false,
      ));
    } catch (_) {
      if (_disposed || isClosed) return;

      emit(state.copyWith(loading: false));
    } finally {
      _busy = false;
    }
  }

  void setCount(int count) {
    if (_disposed || isClosed) return;
    emit(state.copyWith(count: count));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState stateValue) {
    if (_disposed || isClosed) return;

    if (stateValue == AppLifecycleState.resumed) {
      refresh(silent: true);
    }
  }

  @override
  Future<void> close() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}