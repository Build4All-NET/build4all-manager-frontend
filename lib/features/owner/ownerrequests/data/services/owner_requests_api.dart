import 'dart:io';
import 'package:build4all_manager/features/owner/ownerrequests/data/models/currency_model.dart';
import 'package:dio/dio.dart';

class OwnerRequestApi {
  final Dio dio;
  final String baseUrl; // e.g. http://192.168.1.3:8080

  OwnerRequestApi({required this.dio, required this.baseUrl});

  String _cleanBase() => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  /// GET {{baseUrl}}/api/currencies
  Future<List<CurrencyModel>> fetchCurrencies() async {
    final url = '${_cleanBase()}/api/currencies';
    final res = await dio.get(url);
    final data = res.data;

    if (data is List) {
      return data
          .map((e) => CurrencyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Unexpected currencies response shape');
  }

  /// POST {{baseUrl}}/api/app-requests (CHANGE endpoint if yours differs)
  /// Sends multipart/form-data exactly like Postman screenshot.
  Future<void> submitOwnerRequest({
    String? themeId, // optional (your screenshot had it unchecked)
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
    String? apiBaseUrlOverride, // optional
    File? logoFile, // optional
  }) async {
    final url = '${_cleanBase()}/api/app-requests'; // 🔥 update if needed

    final form = FormData();

    // Text fields (backend converts JSON strings to base64)
    if (themeId != null && themeId.trim().isNotEmpty) {
      form.fields.add(MapEntry('themeId', themeId.trim()));
    }

    form.fields
      ..add(MapEntry('notes', notes))
      ..add(MapEntry('primaryColor', primaryColor))
      ..add(MapEntry('secondaryColor', secondaryColor))
      ..add(MapEntry('backgroundColor', backgroundColor))
      ..add(MapEntry('onBackgroundColor', onBackgroundColor))
      ..add(MapEntry('errorColor', errorColor))
      ..add(MapEntry('currencyId', currencyId.toString()))
      ..add(MapEntry('navJson', navJson))
      ..add(MapEntry('homeJson', homeJson))
      ..add(MapEntry('enabledFeaturesJson', enabledFeaturesJson))
      ..add(MapEntry('brandingJson', brandingJson));

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
            filename: logoFile.path.split(Platform.pathSeparator).last,
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
