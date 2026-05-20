import 'package:dio/dio.dart';
import '../models/country_model.dart';

class CountryApi {
  final Dio _dio;

  CountryApi(this._dio);

  Future<List<CountryModel>> getActiveCountries() async {
    final res = await _dio.get('/countries/active');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(CountryModel.fromJson)
          .toList();
    }
    return [];
  }
}
