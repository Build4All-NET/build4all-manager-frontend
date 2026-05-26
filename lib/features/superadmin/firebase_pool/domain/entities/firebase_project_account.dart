class FirebaseProjectAccount {
  final int id;
  final String firebaseProjectId;
  final String displayName;
  final String status; // ACTIVE, RESERVED, DISABLED, RATE_LIMITED, FULL, FAILED
  final int priority;
  final int maxAndroidApps;
  final int maxIosApps;
  final int usedAndroidApps;
  final int usedIosApps;
  final bool isDefault;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FirebaseProjectAccount({
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

  bool get isActive => status == 'ACTIVE';
  int get remainingAndroid =>
      (maxAndroidApps - usedAndroidApps).clamp(0, maxAndroidApps);
  int get remainingIos =>
      (maxIosApps - usedIosApps).clamp(0, maxIosApps);
}
