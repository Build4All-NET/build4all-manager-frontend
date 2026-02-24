abstract class TutorialRepository {
  Future<String?> getOwnerGuide({String? token});

  Future<String?> uploadOwnerGuide({
    required String token,
    required String filePath,
    required void Function(int sent, int total) onSendProgress,
  });
}