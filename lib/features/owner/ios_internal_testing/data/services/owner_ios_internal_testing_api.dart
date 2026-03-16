import 'package:dio/dio.dart';

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

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final requestJson = raw['request'];
        if (requestJson is Map<String, dynamic>) {
          return IosInternalTestingRequestModel.fromJson(requestJson);
        }
        return IosInternalTestingRequestModel.fromJson(raw);
      }

      throw Exception('Invalid create request response format');
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['error'] != null)
              ? e.response!.data['error'].toString()
              : e.message ?? 'Failed to create iOS internal testing request';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to create iOS internal testing request: $e');
    }
  }

  Future<IosInternalTestingRequestModel?> getLatestRequest({
    required int linkId,
  }) async {
    try {
      final response = await _dio.get(
        '/owner/apps/$linkId/ios-internal-requests/latest',
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final requestJson = raw['request'];
        if (requestJson is Map<String, dynamic>) {
          return IosInternalTestingRequestModel.fromJson(requestJson);
        }
        return IosInternalTestingRequestModel.fromJson(raw);
      }

      throw Exception('Invalid latest request response format');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      final msg =
          (e.response?.data is Map && e.response?.data['error'] != null)
              ? e.response!.data['error'].toString()
              : e.message ?? 'Failed to load latest iOS internal testing request';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to load latest iOS internal testing request: $e');
    }
  }

  Future<IosInternalTestingAppSummaryModel> getRequestsSummaryForApp({
    required int linkId,
  }) async {
    try {
      final response = await _dio.get(
        '/owner/apps/$linkId/ios-internal-requests',
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return IosInternalTestingAppSummaryModel.fromJson(raw);
      }

      throw Exception('Invalid iOS internal testing summary response format');
    } on DioException catch (e) {
      final msg =
          (e.response?.data is Map && e.response?.data['error'] != null)
              ? e.response!.data['error'].toString()
              : e.message ?? 'Failed to load iOS internal testing requests';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to load iOS internal testing requests: $e');
    }
  }
}