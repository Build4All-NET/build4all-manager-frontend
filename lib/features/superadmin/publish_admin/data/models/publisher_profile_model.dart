import '../../domain/entities/publisher_profile.dart';

class PublisherProfileModel {
  final int id;
  final String store;
  final String developerName;
  final String developerEmail;
  final String privacyPolicyUrl;

  const PublisherProfileModel({
    required this.id,
    required this.store,
    required this.developerName,
    required this.developerEmail,
    required this.privacyPolicyUrl,
  });

  factory PublisherProfileModel.fromJson(Map<String, dynamic> j) {
    return PublisherProfileModel(
      id: (j['id'] as num).toInt(),
      store: (j['store'] ?? '').toString(),
      developerName: (j['developerName'] ?? '').toString(),
      developerEmail: (j['developerEmail'] ?? '').toString(),
      privacyPolicyUrl: (j['privacyPolicyUrl'] ?? '').toString(),
    );
  }

  PublisherProfile toEntity() => PublisherProfile(
        id: id,
        store: store,
        developerName: developerName,
        developerEmail: developerEmail,
        privacyPolicyUrl: privacyPolicyUrl,
      );
}
