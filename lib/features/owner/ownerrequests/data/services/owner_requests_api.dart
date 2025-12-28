import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import '../models/currency_model.dart';
import '../../../common/data/models/app_request_dto.dart';

class OwnerRequestApi {
  final Dio dio;
  final String baseUrl; // ex: http://192.168.1.3:8080 OR http://.../api

  OwnerRequestApi({required this.dio, required this.baseUrl});

  String _cleanBase() => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  String _apiRoot() {
    var b = _cleanBase();
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  void _ensureValidJson(String value, String fieldName) {
    try {
      json.decode(value);
    } catch (_) {
      throw Exception('$fieldName is not valid JSON.');
    }
  }

  /// GET {base}/api/currencies
  Future<List<CurrencyModel>> fetchCurrencies() async {
    final url = '${_apiRoot()}/currencies';
    final res = await dio.get(url);

    final data = res.data;
    if (data is List) {
      return data
          .map((e) => CurrencyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Unexpected currencies response (expected List).');
  }

  Future<void> submitOwnerRequest({
    required int ownerId,
    required int projectId,
    required String appName,
    required String notes,
    required String primaryColor,
    required String secondaryColor,
    required String backgroundColor,
    required String onBackgroundColor,
    required String errorColor,
    required int currencyId,
    required String navJson,
    required String homeJson,
    required String enabledFeaturesJson,
    required String brandingJson,
    String? apiBaseUrlOverride,
    String? themeId,
    String? slug,
    File? logoFile,
  }) async {
    // validate JSON before sending
    _ensureValidJson(navJson, 'navJson');
    _ensureValidJson(homeJson, 'homeJson');
    _ensureValidJson(enabledFeaturesJson, 'enabledFeaturesJson');
    _ensureValidJson(brandingJson, 'brandingJson');

    final url = '${_apiRoot()}/owner/app-requests/auto';

    final form = FormData();
    form.fields.addAll([
      MapEntry('ownerId', ownerId.toString()),
      MapEntry('projectId', projectId.toString()),
      MapEntry('appName', appName.trim()),
      MapEntry('notes', notes.trim()),
      MapEntry('primaryColor', primaryColor.trim()),
      MapEntry('secondaryColor', secondaryColor.trim()),
      MapEntry('backgroundColor', backgroundColor.trim()),
      MapEntry('onBackgroundColor', onBackgroundColor.trim()),
      MapEntry('errorColor', errorColor.trim()),
      MapEntry('currencyId', currencyId.toString()),
      MapEntry('navJson', navJson),
      MapEntry('homeJson', homeJson),
      MapEntry('enabledFeaturesJson', enabledFeaturesJson),
      MapEntry('brandingJson', brandingJson),
    ]);

    if (themeId != null && themeId.trim().isNotEmpty) {
      form.fields.add(MapEntry('themeId', themeId.trim()));
    }
    if (slug != null && slug.trim().isNotEmpty) {
      form.fields.add(MapEntry('slug', slug.trim()));
    }
    if (apiBaseUrlOverride != null && apiBaseUrlOverride.trim().isNotEmpty) {
      form.fields
          .add(MapEntry('apiBaseUrlOverride', apiBaseUrlOverride.trim()));
    }

    if (logoFile != null) {
      form.files.add(
        MapEntry(
          'logo',
          await MultipartFile.fromFile(
            logoFile.path,
            filename: logoFile.uri.pathSegments.isNotEmpty
                ? logoFile.uri.pathSegments.last
                : 'logo.png',
          ),
        ),
      );
    }

    await dio.post(
      url,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
