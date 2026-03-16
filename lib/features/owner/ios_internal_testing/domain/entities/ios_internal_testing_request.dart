class IosInternalTestingRequest {
  final int id;
  final int ownerProjectLinkId;
  final int ownerId;
  final int projectId;

  final String appNameSnapshot;
  final String bundleIdSnapshot;

  final String appleEmail;
  final String firstName;
  final String lastName;

  final String status;
  final String? appleUserId;
  final String? appleInvitationId;
  final String? lastError;

  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IosInternalTestingRequest({
    required this.id,
    required this.ownerProjectLinkId,
    required this.ownerId,
    required this.projectId,
    required this.appNameSnapshot,
    required this.bundleIdSnapshot,
    required this.appleEmail,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.appleUserId,
    this.appleInvitationId,
    this.lastError,
    this.requestedAt,
    this.processedAt,
    this.acceptedAt,
    this.readyAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isReady => status.toUpperCase() == 'READY';

  bool get isWaitingAcceptance =>
      status.toUpperCase() == 'WAITING_OWNER_ACCEPTANCE';

  bool get isFailed => status.toUpperCase() == 'FAILED';

  bool get isProcessing =>
      status.toUpperCase() == 'PROCESSING' ||
      status.toUpperCase() == 'REQUESTED';

  bool get hasError => (lastError ?? '').trim().isNotEmpty;
}