import 'package:bloc/bloc.dart';
import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import 'admin_notifications_event.dart';
import 'admin_notifications_state.dart';

class AdminNotificationsBloc
    extends Bloc<AdminNotificationsEvent, AdminNotificationsState> {
  final AdminNotificationsApi api;

  AdminNotificationsBloc(this.api) : super(AdminNotificationsState.initial()) {
    on<AdminNotificationsStarted>(_onLoad);
    on<AdminNotificationsRefreshed>(_onLoad);
    on<AdminNotificationMarkedRead>(_onMarkRead);
    on<AdminNotificationDeleted>(_onDelete);
  }

  Future<void> _onLoad(
    AdminNotificationsEvent event,
    Emitter<AdminNotificationsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final items = await api.getNotifications();
      final unread = await api.getUnreadCount();

      emit(state.copyWith(
        loading: false,
        items: items,
        unreadCount: unread,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(e),
      ));
    }
  }

  Future<void> _onMarkRead(
    AdminNotificationMarkedRead event,
    Emitter<AdminNotificationsState> emit,
  ) async {
    try {
      await api.markAsRead(event.id);

      final updated = state.items.map((n) {
        if (n != null && n.id == event.id) {
          return n.copyWithForRead();
        }
        return n;
      }).toList();

      final unread = updated.where((e) => !e.isRead).length;

      emit(state.copyWith(
        items: updated,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(state.copyWith(error: ApiErrorHandler.message(e)));
    }
  }

  Future<void> _onDelete(
    AdminNotificationDeleted event,
    Emitter<AdminNotificationsState> emit,
  ) async {
    try {
      await api.deleteNotification(event.id);

      final updated = state.items.where((n) => n?.id != event.id).toList();
      final unread = updated.where((e) => !e!.isRead).length;

      emit(state.copyWith(
        items: updated,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(state.copyWith(error: ApiErrorHandler.message(e)));
    }
  }
}