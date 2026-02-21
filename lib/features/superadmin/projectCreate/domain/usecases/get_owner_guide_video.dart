import '../repositories/tutorial_repository.dart';

class GetOwnerGuideVideo {
  final TutorialRepository repo;
  GetOwnerGuideVideo(this.repo);

  Future<String?> call({String? token}) {
    return repo.getOwnerGuide(token: token);
  }
}