import '../repositories/tutorial_repository.dart';

class UploadOwnerGuideVideo {
  final TutorialRepository repo;
  UploadOwnerGuideVideo(this.repo);

  Future<String?> call({
    required String token,
    required String filePath,
    required void Function(int sent, int total) onSendProgress,
  }) {
    return repo.uploadOwnerGuide(
      token: token,
      filePath: filePath,
      onSendProgress: onSendProgress,
    );
  }
}