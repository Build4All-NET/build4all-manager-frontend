import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

import '../models/upgrade_plan_option_model.dart';

class OwnerLicensingApi {
  final Dio _dio;
  OwnerLicensingApi(this._dio);

  String get _base => g.appServerRoot;

  Never _throw(Response res) {
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      error: _extractError(res),
    );
  }

  String _extractError(Response res) {
    final data = res.data;
    if (data is Map) {
      final e = data['error'] ?? data['message'];
      if (e is String && e.trim().isNotEmpty) return e;
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return 'HTTP ${res.statusCode ?? '???'}';
  }

  bool _isOk(Response res) {
    final code = res.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] ?? raw['content'] ?? []) : []);
    return (list as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<UpgradePlanOptionModel>> getUpgradePlans() async {
    final res = await _dio.get('$_base/licensing/apps/me/upgrade-plans');
    if (!_isOk(res)) _throw(res);
    return _parseList(res.data, UpgradePlanOptionModel.fromJson);
  }

  Future<void> sendUpgradeRequest({
    required String planCode,
    required String billingCycle,
  }) async {
    final res = await _dio.post(
      '$_base/licensing/apps/me/upgrade-request',
      data: {'planCode': planCode, 'billingCycle': billingCycle},
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );
    if (!_isOk(res)) _throw(res);
  }
}
