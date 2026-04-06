import 'package:build4all_manager/features/owner/app_build/data/models/build_status_models.dart';
import 'package:dio/dio.dart';

class OwnerBuildJobsApi {
  final Dio _dio;

  OwnerBuildJobsApi(this._dio);

  /// Get build status for a specific project/app by linkId (or projectId)
  Future<BuildStatusResponse> getBuildStatus(int linkId) async {
    final response = await _dio.get('/owner/apps/$linkId/build-status');

    return BuildStatusResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}