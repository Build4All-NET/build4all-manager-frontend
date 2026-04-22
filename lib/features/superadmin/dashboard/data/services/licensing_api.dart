import 'package:build4all_manager/features/superadmin/dashboard/data/models/super_admin_app_license_row.dart';
import 'package:dio/dio.dart';

class LicensingApi {
  final Dio dio;

  LicensingApi(this.dio);

  /// GET /api/licensing/upgrade-requests/pending
  Future<Response> pendingUpgradeRequests() =>
      dio.get('/licensing/upgrade-requests/pending');

  /// POST /api/licensing/upgrade-requests/{id}/approve
  Future<Response> approveUpgradeRequest(int requestId) =>
      dio.post('/licensing/upgrade-requests/$requestId/approve');

  /// POST /api/licensing/upgrade-requests/{id}/reject
  Future<Response> rejectUpgradeRequest(
    int requestId, {
    String? note,
  }) =>
      dio.post(
        '/licensing/upgrade-requests/$requestId/reject',
        data: {'note': note},
      );

  /// POST /api/licensing/apps/{aupId}/cancel-license
  Future<Response> cancelLicense(int aupId) =>
      dio.post('/licensing/apps/$aupId/cancel-license');

  /// POST /api/licensing/upgrade-requests/{id}/mark-paid
  Future<Response> markUpgradeRequestPaid(int requestId) =>
      dio.post('/licensing/upgrade-requests/$requestId/mark-paid');

  /// POST /api/licensing/upgrade-requests/{id}/mark-unpaid
  Future<Response> markUpgradeRequestUnpaid(int requestId) =>
      dio.post('/licensing/upgrade-requests/$requestId/mark-unpaid');

  /// GET /api/licensing/upgrade-requests/recently-approved?days=7
  Future<Response> recentlyApprovedUpgradeRequests({int days = 7}) =>
      dio.get(
        '/licensing/upgrade-requests/recently-approved',
        queryParameters: {'days': days},
      );

  /// GET /api/licensing/apps
  Future<List<SuperAdminAppLicenseRow>> listAppsLicenses() async {
    final res = await dio.get('/licensing/apps');
    final data = (res.data as List?) ?? const [];

    return data
        .map((e) => SuperAdminAppLicenseRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}