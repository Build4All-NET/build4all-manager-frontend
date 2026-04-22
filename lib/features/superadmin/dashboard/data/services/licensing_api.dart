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

  /// POST /api/licensing/upgrade-requests/{id}/reject  body: {note}
  Future<Response> rejectUpgradeRequest(int requestId, {String? note}) =>
      dio.post(
        '/licensing/upgrade-requests/$requestId/reject',
        data: {'note': note},
      );

<<<<<<< HEAD
Future<Response> cancelLicense(int aupId) {
  return dio.post('/licensing/apps/$aupId/cancel-license');
}
=======
  /// POST /api/licensing/upgrade-requests/{id}/mark-paid
  /// Cash/manual flow: confirms cash was collected at the counter and
  /// activates the subscription for the billing cycle the owner picked.
  Future<Response> markUpgradeRequestPaid(int requestId) =>
      dio.post('/licensing/upgrade-requests/$requestId/mark-paid');

  /// POST /api/licensing/upgrade-requests/{id}/mark-unpaid
  /// Reverses a cash Mark-Paid: cancels the activated subscription,
  /// flips the payment to FAILED and moves the request back to PENDING.
  /// Only valid for cash/manual rows.
  Future<Response> markUpgradeRequestUnpaid(int requestId) =>
      dio.post('/licensing/upgrade-requests/$requestId/mark-unpaid');

  /// GET /api/licensing/upgrade-requests/recently-approved?days=N
  /// Recently approved cash upgrades so the UI can offer an Undo.
  Future<Response> recentlyApprovedUpgradeRequests({int days = 7}) =>
      dio.get(
        '/licensing/upgrade-requests/recently-approved',
        queryParameters: {'days': days},
      );

>>>>>>> 1029f512ea6a391f96dbe4165ca0ff6b962bbab3

      Future<List<SuperAdminAppLicenseRow>> listAppsLicenses() async {
  final res = await dio.get('/licensing/apps');
  final data = (res.data as List?) ?? const [];
  return data
      .map((e) => SuperAdminAppLicenseRow.fromJson(e as Map<String, dynamic>))
      .toList();
}

}
