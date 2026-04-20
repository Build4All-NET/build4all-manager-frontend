import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:dio/dio.dart';

import '../dto/payment_method_dto.dart';
import '../dto/payment_type_dto.dart';
import 'i_payment_management_service.dart';

class PaymentManagementServiceImpl implements IPaymentManagementService {
  final Dio _dio;
  PaymentManagementServiceImpl(this._dio);

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

  Options get _mutationOptions => Options(
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.plain,
      );

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['data'] ?? raw['content'] ?? []) : []);
    return (list as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Payment Methods ──────────────────────────────────────────────────────

  @override
  Future<List<PaymentMethodResponseDto>> getPaymentMethods() async {
    final res = await _dio.get('$_base/superadmin/payment-methods');
    if (!_isOk(res)) _throw(res);
    return _parseList(res.data, PaymentMethodResponseDto.fromJson);
  }

  @override
  Future<PaymentMethodResponseDto> getPaymentMethodById(int id) async {
    final res = await _dio.get('$_base/superadmin/payment-methods/$id');
    if (!_isOk(res)) _throw(res);
    return PaymentMethodResponseDto.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  @override
  Future<void> createPaymentMethod(CreatePaymentMethodDto dto) async {
    final res = await _dio.post(
      '$_base/superadmin/payment-methods',
      data: dto.toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }

  @override
  Future<void> updatePaymentMethod(int id, UpdatePaymentMethodDto dto) async {
    final res = await _dio.put(
      '$_base/superadmin/payment-methods/$id',
      data: dto.toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }

  @override
  Future<void> togglePaymentMethod(int id, bool isEnabled) async {
    final res = await _dio.patch(
      '$_base/superadmin/payment-methods/$id/status',
      data: TogglePaymentMethodDto(isEnabled: isEnabled).toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }

  // ── Payment Types ────────────────────────────────────────────────────────

  @override
  Future<List<PaymentTypeResponseDto>> getPaymentTypes() async {
    final res = await _dio.get('$_base/superadmin/payment-types');
    if (!_isOk(res)) _throw(res);
    return _parseList(res.data, PaymentTypeResponseDto.fromJson);
  }

  @override
  Future<void> createPaymentType(CreatePaymentTypeDto dto) async {
    final res = await _dio.post(
      '$_base/superadmin/payment-types',
      data: dto.toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }

  @override
  Future<void> updatePaymentType(int id, UpdatePaymentTypeDto dto) async {
    final res = await _dio.put(
      '$_base/superadmin/payment-types/$id',
      data: dto.toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }

  @override
  Future<void> togglePaymentType(int id, bool isActive) async {
    final res = await _dio.patch(
      '$_base/superadmin/payment-types/$id/status',
      data: TogglePaymentTypeDto(isActive: isActive).toJson(),
      options: _mutationOptions,
    );
    if (!_isOk(res)) _throw(res);
  }
}
