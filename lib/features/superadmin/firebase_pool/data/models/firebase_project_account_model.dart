import '../../domain/entities/firebase_project_account.dart';

class FirebaseProjectAccountModel {
  final int id;
  final String firebaseProjectId;
  final String displayName;
  final String status;
  final int priority;
  final int maxAndroidApps;
  final int maxIosApps;
  final int usedAndroidApps;
  final int usedIosApps;
  final bool isDefault;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FirebaseProjectAccountModel({
    required this.id,
    required this.firebaseProjectId,
    required this.displayName,
    required this.status,
    required this.priority,
    required this.maxAndroidApps,
    required this.maxIosApps,
    required this.usedAndroidApps,
    required this.usedIosApps,
    required this.isDefault,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });

  factory FirebaseProjectAccountModel.fromJson(Map<String, dynamic> j) {
    return FirebaseProjectAccountModel(
      id: j['id'] as int,
      firebaseProjectId: j['firebaseProjectId'] as String? ?? '',
      displayName: j['displayName'] as String? ?? '',
      status: j['status'] as String? ?? 'DISABLED',
      priority: j['priority'] as int? ?? 10,
      maxAndroidApps: j['maxAndroidApps'] as int? ?? 30,
      maxIosApps: j['maxIosApps'] as int? ?? 30,
      usedAndroidApps: j['usedAndroidApps'] as int? ?? 0,
      usedIosApps: j['usedIosApps'] as int? ?? 0,
      isDefault: j['isDefault'] as bool? ?? j['default'] as bool? ?? false,
      lastError: j['lastError'] as String?,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'] as String)
          : null,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'] as String)
          : null,
    );
  }

  FirebaseProjectAccount toEntity() => FirebaseProjectAccount(
        id: id,
        firebaseProjectId: firebaseProjectId,
        displayName: displayName,
        status: status,
        priority: priority,
        maxAndroidApps: maxAndroidApps,
        maxIosApps: maxIosApps,
        usedAndroidApps: usedAndroidApps,
        usedIosApps: usedIosApps,
        isDefault: isDefault,
        lastError: lastError,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
