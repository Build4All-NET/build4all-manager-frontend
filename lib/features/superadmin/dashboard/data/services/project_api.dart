import 'package:dio/dio.dart';

class ProjectApi {
  final Dio dio;
  ProjectApi(this.dio);

  /// GET /projects → list of projects
  Future<Response> list() => dio.get('/projects');

  /// GET /projects/{projectId}/owners → list owners in a project
  Future<Response> ownersByProject(int projectId) =>
      dio.get('/projects/$projectId/owners');

  /// GET /projects/{projectId}/owners/{adminId}/apps → apps for an owner in a project
  Future<Response> ownerAppsInProject(int projectId, int adminId) =>
      dio.get('/projects/$projectId/owners/$adminId/apps');

  /// GET /orders/superadmin/applications/{ownerProjectId}/orders
  /// Returns the list of orders for a specific owner app (ownerProjectId),
  /// using the existing controller:
  ///   @GetMapping("/superadmin/applications/{ownerProjectId}/orders")
  ///   in OrderController (base path: /api/orders).
  Future<Response> ownerAppOrders(int ownerProjectId) =>
      dio.get('/orders/superadmin/applications/$ownerProjectId/orders');
}
