import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/ios_internal_testing_app_summary_model.dart';
import '../models/ios_internal_testing_request_model.dart';

class OwnerIosInternalTestingApi {
  final Dio _dio;

  OwnerIosInternalTestingApi(this._dio);

  Future<IosInternalTestingRequestModel> createRequest({
    required int linkId,
    required String appleEmail,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/owner/apps/$linkId/ios-internal-requests',
        data: {
          'appleEmail': appleEmail.trim(),
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        },
      );

      _logSuccess(
        title: 'CREATE IOS INTERNAL REQUEST',
        response: response,
      );

      final raw = _asMap(response.data);
      final requestJson = _extractRequestMap(raw);

      final model = IosInternalTestingRequestModel.fromJson(requestJson);

      _logParsedRequest(
        title: 'CREATE IOS INTERNAL REQUEST PARSED',
        requestJson: requestJson,
      );

      return model;
    } on DioException catch (e) {
      _logDioError(
        title: 'CREATE IOS INTERNAL REQUEST ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ CREATE IOS INTERNAL REQUEST UNKNOWN ERROR => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<IosInternalTestingRequestModel?> getLatestRequest({
    required int linkId,
  }) async {
    try {
      final response = await _dio.get(
        '/owner/apps/$linkId/ios-internal-requests/latest',
      );

      _logSuccess(
        title: 'GET LATEST IOS INTERNAL REQUEST',
        response: response,
      );

      final raw = _asMap(response.data);
      final requestJson = _extractRequestMap(raw);

      final model = IosInternalTestingRequestModel.fromJson(requestJson);

      _logParsedRequest(
        title: 'GET LATEST IOS INTERNAL REQUEST PARSED',
        requestJson: requestJson,
      );

      return model;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint(
          'ℹ️ No latest iOS internal testing request found for linkId=$linkId',
        );
        return null;
      }

      _logDioError(
        title: 'GET LATEST IOS INTERNAL REQUEST ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ GET LATEST IOS INTERNAL REQUEST UNKNOWN ERROR => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<IosInternalTestingAppSummaryModel> getRequestsSummaryForApp({
    required int linkId,
  }) async {
    try {
      final response = await _dio.get(
        '/owner/apps/$linkId/ios-internal-requests',
      );

      _logSuccess(
        title: 'GET IOS INTERNAL REQUESTS SUMMARY',
        response: response,
      );

      final raw = _asMap(response.data);
      final model = IosInternalTestingAppSummaryModel.fromJson(raw);

      final requests = raw['requests'];
      if (requests is List && requests.isNotEmpty) {
        final last = requests.last;
        if (last is Map) {
          _logParsedRequest(
            title: 'GET IOS INTERNAL REQUESTS SUMMARY LAST REQUEST',
            requestJson: Map<String, dynamic>.from(last),
          );
        }
      }

      return model;
    } on DioException catch (e) {
      _logDioError(
        title: 'GET IOS INTERNAL REQUESTS SUMMARY ERROR',
        error: e,
      );
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ GET IOS INTERNAL REQUESTS SUMMARY UNKNOWN ERROR => $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
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

    if (request is Map<String, dynamic>) {
      return request;
    }

    if (request is Map) {
      return Map<String, dynamic>.from(request);
    }

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

  void _logParsedRequest({
    required String title,
    required Map<String, dynamic> requestJson,
  }) {
    debugPrint('🔎 $title');
    debugPrint('➡️ id => ${requestJson['id']}');
    debugPrint('➡️ status => ${requestJson['status']}');
    debugPrint('➡️ lastError => ${requestJson['lastError']}');
    debugPrint('➡️ appleUserId => ${requestJson['appleUserId']}');
    debugPrint('➡️ appleInvitationId => ${requestJson['appleInvitationId']}');
    debugPrint('➡️ full request => ${_pretty(requestJson)}');
  }

  void _logDioError({
    required String title,
    required DioException error,
  }) {
    debugPrint('❌ $title');
    debugPrint('➡️ PATH => ${error.requestOptions.path}');
    debugPrint('➡️ METHOD => ${error.requestOptions.method}');
    debugPrint('➡️ STATUS CODE => ${error.response?.statusCode}');
    debugPrint('➡️ RESPONSE BODY => ${_pretty(error.response?.data)}');
    debugPrint('➡️ MESSAGE => ${error.message}');
  }

  String _pretty(dynamic value) {
    try {
      if (value == null) return 'null';
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}