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
}
