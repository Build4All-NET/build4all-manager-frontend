import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/super_admin_ios_internal_testing_request_model.dart';

class SuperAdminIosInternalTestingApi {
  final Dio _dio;

  SuperAdminIosInternalTestingApi(this._dio);

  Future<List<SuperAdminIosInternalTestingRequestModel>> getRequests({
    String? status,
    bool manualOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/super-admin/ios-internal-requests',
        queryParameters: {
          if (status != null && status.trim().isNotEmpty && status != 'ALL')
            'status': status.trim(),
          if (manualOnly) 'manualOnly': true,
        },
      );

      _logSuccess(
        title: 'GET SUPER ADMIN IOS INTERNAL REQUESTS',
        response: response,
      );

      final raw = _asMap(response.data);
      final requestsRaw = raw['requests'];

      final list = requestsRaw is List
          ? requestsRaw
              .whereType<Map>()
              .map(
                (e) => SuperAdminIosInternalTestingRequestModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : <SuperAdminIosInternalTestingRequestModel>[];

      return list;
    } on DioException catch (e) {
      _logDioError(
        title: 'GET SUPER ADMIN IOS INTERNAL REQUESTS ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ GET SUPER ADMIN IOS INTERNAL REQUESTS UNKNOWN ERROR => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<SuperAdminIosInternalTestingRequestModel> processRequest(
    int requestId,
  ) async {
    try {
      final response = await _dio.post(
        '/super-admin/ios-internal-requests/$requestId/process',
      );

      _logSuccess(
        title: 'PROCESS SUPER ADMIN IOS INTERNAL REQUEST',
        response: response,
      );

      final raw = _asMap(response.data);
      final requestJson = _extractRequestMap(raw);

      return SuperAdminIosInternalTestingRequestModel.fromJson(requestJson);
    } on DioException catch (e) {
      _logDioError(
        title: 'PROCESS SUPER ADMIN IOS INTERNAL REQUEST ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ PROCESS SUPER ADMIN IOS INTERNAL REQUEST UNKNOWN => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<SuperAdminIosInternalTestingRequestModel> syncRequest(
    int requestId,
  ) async {
    try {
      final response = await _dio.post(
        '/super-admin/ios-internal-requests/$requestId/sync',
      );

      _logSuccess(
        title: 'SYNC SUPER ADMIN IOS INTERNAL REQUEST',
        response: response,
      );

      final raw = _asMap(response.data);
      final requestJson = _extractRequestMap(raw);

      return SuperAdminIosInternalTestingRequestModel.fromJson(requestJson);
    } on DioException catch (e) {
      _logDioError(
        title: 'SYNC SUPER ADMIN IOS INTERNAL REQUEST ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ SYNC SUPER ADMIN IOS INTERNAL REQUEST UNKNOWN => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> syncAll(List<int> requestIds) async {
    int updated = 0;

    for (final id in requestIds) {
      try {
        await syncRequest(id);
        updated++;
      } catch (_) {
        // keep going
      }
    }

    return updated;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw Exception(
      'Invalid response format: expected Map but got ${raw.runtimeType}',
    );
  }

  Map<String, dynamic> _extractRequestMap(Map<String, dynamic> raw) {
    final request = raw['request'];
    if (request is Map<String, dynamic>) return request;
    if (request is Map) return Map<String, dynamic>.from(request);
    return raw;
  }

  void _logSuccess({
    required String title,
    required Response response,
  }) {
    debugPrint('✅ $title');
    debugPrint('➡️ STATUS CODE => ${response.statusCode}');
    debugPrint('➡️ PATH => ${response.requestOptions.path}');
    debugPrint('➡️ RESPONSE BODY => ${_pretty(response.data)}');
  }

  void _logDioError({
    required String title,
    required DioException error,
  }) {
    debugPrint('❌ $title');
    debugPrint('➡️ PATH => ${error.requestOptions.path}');
    debugPrint('➡️ STATUS => ${error.response?.statusCode}');
    debugPrint('➡️ RESPONSE => ${_pretty(error.response?.data)}');
    debugPrint('➡️ MESSAGE => ${error.message}');
  }

  String _pretty(dynamic data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}