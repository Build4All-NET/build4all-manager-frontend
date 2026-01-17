abstract class SuperAdminAiEvent {}

class SuperAdminAiStarted extends SuperAdminAiEvent {
  final int ownerId;
  SuperAdminAiStarted(this.ownerId);
}

class SuperAdminAiToggled extends SuperAdminAiEvent {
  final int ownerId;
  final bool enabled;
  SuperAdminAiToggled({required this.ownerId, required this.enabled});
}
