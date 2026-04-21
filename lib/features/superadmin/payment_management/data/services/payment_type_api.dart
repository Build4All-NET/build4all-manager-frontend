import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

import '../models/managed_payment_type_model.dart';

class PaymentTypeApi {
  final Dio _dio;
  PaymentTypeApi(this._dio);

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
    return "HTTP ${res.statusCode ?? '???'}";
  }

  bool _isOk(Response res) {
    final code = res.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  Future<List<ManagedPaymentTypeModel>> getAll() async {
    final res = await _dio.get('$_base/superadmin/subscription-billing/types');
    if (!_isOk(res)) _throw(res);
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] ?? raw['content'] ?? []) : []);
    return (list as List)
        .map((e) => ManagedPaymentTypeModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    final res = await _dio.post(
      '$_base/superadmin/subscription-billing/types',
      data: body,
      options: Options(
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    if (!_isOk(res)) _throw(res);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    final res = await _dio.put(
      '$_base/superadmin/subscription-billing/types/$id',
      data: body,
      options: Options(
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    if (!_isOk(res)) _throw(res);
  }

  Future<void> toggle(int id, bool isActive) async {
    final res = await _dio.patch(
      '$_base/superadmin/subscription-billing/types/$id/status',
      data: {'isActive': isActive},
      options: Options(
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    if (!_isOk(res)) _throw(res);
  }
}
