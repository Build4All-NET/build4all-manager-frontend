import 'dart:io';
import 'package:dio/dio.dart';

import '../../../common/data/models/app_request_dto.dart';

class OwnerRequestApi {
  final Dio dio;
  final String baseUrl;

  OwnerRequestApi({required this.dio, required this.baseUrl});

  String _apiRoot() {
    var b = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    // ensure /api at end if your app uses it (adjust if yours already includes /api)
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }


  // ✅ NEW: manual create (FormData, raw json strings)
  Future<AppRequestDto> createManual({
    required int ownerId,
    required int projectId,
    required String appName,
    required int currencyId,
    required String notes,
    required String primaryColor,
    required String secondaryColor,
    required String backgroundColor,
    required String onBackgroundColor,
    required String errorColor,
    required String navJson,
    required String homeJson,
    required String enabledFeaturesJson,
    required String brandingJson,
    String? apiBaseUrlOverride,
    int? themeId,
    String? slug,
    String? logoFilePath,
  }) async {
    final form = FormData();

    form.fields.addAll([
      MapEntry('ownerId', ownerId.toString()),
      MapEntry('projectId', projectId.toString()),
      MapEntry('appName', appName),

      MapEntry('notes', notes),

      MapEntry('primaryColor', primaryColor),
      MapEntry('secondaryColor', secondaryColor),
      MapEntry('backgroundColor', backgroundColor),
      MapEntry('onBackgroundColor', onBackgroundColor),
      MapEntry('errorColor', errorColor),

      // ✅ IMPORTANT: matches screenshot key exactly
      MapEntry('currencyId', currencyId.toString()),

      // ✅ IMPORTANT: raw json text (backend base64 it)
      MapEntry('navJson', navJson),
      MapEntry('homeJson', homeJson),
      MapEntry('enabledFeaturesJson', enabledFeaturesJson),
      MapEntry('brandingJson', brandingJson),
    ]);

    if (themeId != null) {
      form.fields.add(MapEntry('themeId', themeId.toString()));
    }
    if (slug != null && slug.trim().isNotEmpty) {
      form.fields.add(MapEntry('slug', slug.trim()));
    }
    if (apiBaseUrlOverride != null && apiBaseUrlOverride.trim().isNotEmpty) {
      form.fields
          .add(MapEntry('apiBaseUrlOverride', apiBaseUrlOverride.trim()));
    }

    // ✅ optional logo file
    if (logoFilePath != null && logoFilePath.trim().isNotEmpty) {
      final f = File(logoFilePath);
      if (await f.exists()) {
        form.files.add(
          MapEntry(
            'logo',
            await MultipartFile.fromFile(
              f.path,
              filename: f.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
    }

    // 🔥 Update endpoint to match your backend mapping
    final res = await dio.post(
      '${_apiRoot()}/owner/requests/create-manual', // <-- change if needed
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    return AppRequestDto.fromJson(Map<String, dynamic>.from(res.data));
  }
}
