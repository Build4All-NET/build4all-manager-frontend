import '../repositories/tutorial_repository.dart';

class SaveOwnerGuideUrl {
  final TutorialRepository repo;

  SaveOwnerGuideUrl(this.repo);

  Future<String?> call({
    required String token,
    required String videoUrl,
  }) {
    return repo.saveOwnerGuideUrl(
      token: token,
      videoUrl: videoUrl,
    );
  }
}