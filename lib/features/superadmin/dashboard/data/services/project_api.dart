import 'package:dio/dio.dart';

class ProjectApi {
  final Dio dio;
  ProjectApi(this.dio);

  /// GET /projects → full list for Super Admin management
  Future<Response> list() => dio.get('/projects');

  /// PUT /projects/{projectId} → update template card fields
  Future<Response> updateProject(int projectId, Map<String, dynamic> data) =>
      dio.put('/projects/$projectId', data: data);

  /// GET /projects/{projectId}/owners → list owners in a project
  Future<Response> ownersByProject(int projectId) =>
      dio.get('/projects/$projectId/owners');

  /// GET /projects/{projectId}/owners/{adminId}/apps → apps for an owner in a project
  Future<Response> ownerAppsInProject(int projectId, int adminId) =>
      dio.get('/projects/$projectId/owners/$adminId/apps');

  /// GET /orders/superadmin/applications/{ownerProjectId}/orders
  Future<Response> ownerAppOrders(int ownerProjectId) =>
      dio.get('/orders/superadmin/applications/$ownerProjectId/orders');

  Future<Response> enableProject(int projectId) =>
      dio.put('/projects/$projectId/enable');

  Future<Response> disableProject(int projectId) =>
      dio.put('/projects/$projectId/disable');

  Future<Response> archiveProject(int projectId) =>
      dio.put('/projects/$projectId/archive');
}
