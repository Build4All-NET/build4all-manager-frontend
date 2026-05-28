abstract class FirebasePoolEvent {}

class LoadFirebasePool extends FirebasePoolEvent {}

class RefreshFirebasePool extends FirebasePoolEvent {}

class EnableFirebaseAccount extends FirebasePoolEvent {
  final int id;
  EnableFirebaseAccount(this.id);
}

class DisableFirebaseAccount extends FirebasePoolEvent {
  final int id;
  DisableFirebaseAccount(this.id);
}

class SetDefaultFirebaseAccount extends FirebasePoolEvent {
  final int id;
  SetDefaultFirebaseAccount(this.id);
}

class SaveFirebaseAccount extends FirebasePoolEvent {
  final int? id; // null = create new
  final String firebaseProjectId;
  final String displayName;
  final String serviceAccountCredentialsJson;
  final int priority;
  final int maxAndroidApps;
  final int maxIosApps;
  final bool isDefault;

  SaveFirebaseAccount({
    this.id,
    required this.firebaseProjectId,
    required this.displayName,
    required this.serviceAccountCredentialsJson,
    required this.priority,
    required this.maxAndroidApps,
    required this.maxIosApps,
    required this.isDefault,
  });
}
