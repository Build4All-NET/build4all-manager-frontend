import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class TutorialApi {
  final Dio dio;
  TutorialApi(this.dio);

  Future<String?> getOwnerGuide({String? token}) async {
    final r = await dio.get(
      '/tutorial/owner-guide',
      options: (token == null || token.trim().isEmpty)
          ? null
          : Options(headers: {'Authorization': 'Bearer ${token.trim()}'}),
    );

    final data = r.data;
    if (data is Map && data['data'] is Map) {
      return data['data']['videoUrl']?.toString();
    }
    return null;
  }

  Future<String?> uploadOwnerGuide({
    required String token,
    required String filePath,
    required void Function(int sent, int total) onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'owner_guide.mp4',
        contentType: MediaType('video', 'mp4'),
      ),
    });

    final r = await dio.post(
      '/superadmin/tutorial/owner-guide/upload',
      data: form,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${token.trim()}',
          'Content-Type': 'multipart/form-data',
        },
      ),
      onSendProgress: onSendProgress,
    );

    final data = r.data;
    if (data is Map && data['data'] is Map) {
      return data['data']['videoUrl']?.toString();
    }
    return null;
  }
}