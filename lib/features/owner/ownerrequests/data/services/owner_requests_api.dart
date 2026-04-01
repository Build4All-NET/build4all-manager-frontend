import 'dart:convert';
import 'dart:io';

import 'package:build4all_manager/core/utils/upload_safe_image_normalizer.dart';
import 'package:dio/dio.dart';

import '../models/currency_model.dart';

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
  _ensureValidJson(navJson, 'navJson');
  _ensureValidJson(homeJson, 'homeJson');
  _ensureValidJson(enabledFeaturesJson, 'enabledFeaturesJson');
  _ensureValidJson(brandingJson, 'brandingJson');

  final url = '${_apiRoot()}/owner/app-requests/auto/both';

  final form = FormData();
  form.fields.addAll([
   
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
    form.fields.add(MapEntry('apiBaseUrlOverride', apiBaseUrlOverride.trim()));
  }

  if (logoFile != null) {
    final safeLogo = await UploadSafeImageNormalizer.normalizeForUpload(
      logoFile,
      prefix: 'owner_logo_upload',
      quality: 88,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    form.files.add(
      MapEntry(
        'logo',
        await MultipartFile.fromFile(
          safeLogo.path,
          filename: safeLogo.uri.pathSegments.isNotEmpty
              ? safeLogo.uri.pathSegments.last
              : 'logo.jpg',
        ),
      ),
    );
  }

  try {
    final res = await dio.post(
      url,
      data: form,
    );

    print('AUTO BOTH STATUS => ${res.statusCode}');
    print('AUTO BOTH DATA => ${res.data}');
  } on DioException catch (e) {
    print('AUTO BOTH URL => $url');
    print('AUTO BOTH STATUS => ${e.response?.statusCode}');
    print('AUTO BOTH DATA => ${e.response?.data}');
    print('AUTO BOTH MESSAGE => ${e.message}');
    rethrow;
  } catch (e) {
    print('AUTO BOTH UNKNOWN ERROR => $e');
    rethrow;
  }
}
}
