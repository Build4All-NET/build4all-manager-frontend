// lib/features/owner/app_build/data/services/owner_build_jobs_api.dart

import 'package:build4all_manager/features/owner/app_build/data/models/build_status_models.dart';
import 'package:dio/dio.dart';



class OwnerBuildJobsApi {
  final Dio _dio;

  OwnerBuildJobsApi(this._dio);

  /// Get build status for a specific project/app by linkId (or projectId)
  Future<BuildStatusResponse> getBuildStatus(int linkId) async {
    try {
      final response = await _dio.get('/owner/apps/$linkId/build-status');

      return BuildStatusResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // You can log or rethrow with more context
      throw Exception(
        'Failed to load build status: ${e.response?.statusCode} ${e.message}',
      );
    } catch (e) {
      throw Exception('Failed to load build status: $e');
    }
  }
}
