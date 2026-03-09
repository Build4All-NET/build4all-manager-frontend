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

  AdminUnreadCountCubit(this.api) : super(AdminUnreadCountState.initial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> start() async {
    await refresh();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      refresh(silent: true);
    });
  }

  Future<void> refresh({bool silent = false}) async {
    if (_busy) return;
    _busy = true;

    if (!silent) {
      emit(state.copyWith(loading: true));
    }

    try {
      final count = await api.getUnreadCount();
      emit(state.copyWith(
        count: count,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    } finally {
      _busy = false;
    }
  }

  void setCount(int count) {
    emit(state.copyWith(count: count));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState stateValue) {
    if (stateValue == AppLifecycleState.resumed) {
      refresh(silent: true);
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    return super.close();
  }
}