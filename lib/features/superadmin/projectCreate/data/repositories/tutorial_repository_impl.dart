import '../../domain/repositories/tutorial_repository.dart';
import '../services/tutorial_api.dart';

class TutorialRepositoryImpl implements TutorialRepository {
  final TutorialApi api;
  TutorialRepositoryImpl(this.api);

  @override
  Future<String?> getOwnerGuide({String? token}) {
    return api.getOwnerGuide(token: token);
  }

  @override
  Future<String?> uploadOwnerGuide({
    required String token,
    required String filePath,
    required void Function(int sent, int total) onSendProgress,
  }) {
    return api.uploadOwnerGuide(
      token: token,
      filePath: filePath,
      onSendProgress: onSendProgress,
    );
  }
}