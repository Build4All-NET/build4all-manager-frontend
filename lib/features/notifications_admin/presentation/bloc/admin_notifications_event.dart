abstract class AdminNotificationsEvent {
  const AdminNotificationsEvent();
}

class AdminNotificationsStarted extends AdminNotificationsEvent {
  const AdminNotificationsStarted();
}

class AdminNotificationsRefreshed extends AdminNotificationsEvent {
  const AdminNotificationsRefreshed();
}

class AdminNotificationMarkedRead extends AdminNotificationsEvent {
  final int id;
  const AdminNotificationMarkedRead(this.id);
}

class AdminNotificationDeleted extends AdminNotificationsEvent {
  final int id;
  const AdminNotificationDeleted(this.id);
}