import 'package:equatable/equatable.dart';

class SuperAdminIosInternalTestingRequestModel extends Equatable {
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

  const SuperAdminIosInternalTestingRequestModel({
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

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return fallback;
    return s;
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  static DateTime? _asDateTime(dynamic v) {
    final s = _asNullableString(v);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  factory SuperAdminIosInternalTestingRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SuperAdminIosInternalTestingRequestModel(
      id: _asInt(json['id']),
      ownerProjectLinkId: _asInt(json['ownerProjectLinkId']),
      ownerId: _asInt(json['ownerId']),
      projectId: _asInt(json['projectId']),
      appNameSnapshot: _asString(json['appNameSnapshot']),
      bundleIdSnapshot: _asString(json['bundleIdSnapshot']),
      appleEmail: _asString(json['appleEmail']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      status: _asString(json['status'], fallback: 'UNKNOWN'),
      appleUserId: _asNullableString(json['appleUserId']),
      appleInvitationId: _asNullableString(json['appleInvitationId']),
      lastError: _asNullableString(json['lastError']),
      requestedAt: _asDateTime(json['requestedAt']),
      processedAt: _asDateTime(json['processedAt']),
      acceptedAt: _asDateTime(json['acceptedAt']),
      readyAt: _asDateTime(json['readyAt']),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  bool get isReady => status.trim().toUpperCase() == 'READY';

  bool get isFailed => status.trim().toUpperCase() == 'FAILED';

  bool get isWaiting =>
      status.trim().toUpperCase() == 'WAITING_OWNER_ACCEPTANCE';

  bool get isAdding =>
      status.trim().toUpperCase() == 'ADDING_TO_INTERNAL_TESTING';

  bool get isSyncable {
    final s = status.trim().toUpperCase();
    return s == 'WAITING_OWNER_ACCEPTANCE' ||
        s == 'INVITED_TO_APPLE_TEAM' ||
        s == 'ADDING_TO_INTERNAL_TESTING' ||
        s == 'FAILED';
  }

  @override
  List<Object?> get props => [
        id,
        ownerProjectLinkId,
        ownerId,
        projectId,
        appNameSnapshot,
        bundleIdSnapshot,
        appleEmail,
        firstName,
        lastName,
        status,
        appleUserId,
        appleInvitationId,
        lastError,
        requestedAt,
        processedAt,
        acceptedAt,
        readyAt,
        createdAt,
        updatedAt,
      ];
}