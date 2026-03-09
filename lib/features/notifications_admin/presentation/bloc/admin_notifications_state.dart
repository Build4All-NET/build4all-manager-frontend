import 'package:build4all_manager/features/notifications_admin/data/model/admin_notification_model.dart';


class AdminNotificationsState {
  final bool loading;
  final bool acting;
  final String? error;
  final List<AdminNotificationModel> items;
  final int unreadCount;

  const AdminNotificationsState({
    required this.loading,
    required this.acting,
    required this.error,
    required this.items,
    required this.unreadCount,
  });

  factory AdminNotificationsState.initial() {
    return const AdminNotificationsState(
      loading: true,
      acting: false,
      error: null,
      items: [],
      unreadCount: 0,
    );
  }

  AdminNotificationsState copyWith({
    bool? loading,
    bool? acting,
    String? error,
    List<AdminNotificationModel>? items,
    int? unreadCount,
    bool clearError = false,
  }) {
    return AdminNotificationsState(
      loading: loading ?? this.loading,
      acting: acting ?? this.acting,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}