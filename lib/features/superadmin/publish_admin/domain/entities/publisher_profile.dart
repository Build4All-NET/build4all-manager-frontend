class PublisherProfile {
  final int id;
  final String store; // PLAY_STORE / APP_STORE
  final String developerName;
  final String developerEmail;
  final String privacyPolicyUrl;

  const PublisherProfile({
    required this.id,
    required this.store,
    required this.developerName,
    required this.developerEmail,
    required this.privacyPolicyUrl,
  });
}
