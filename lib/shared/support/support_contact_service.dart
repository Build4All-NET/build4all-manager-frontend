import 'package:dio/dio.dart';

/// Fetches the SUPER_ADMIN support contact (WhatsApp/phone) from the backend.
///
/// The number lives on the SUPER_ADMIN profile — there is no separate screen
/// to manage it. This service only reads the publicly exposed phone number.
class SupportContactService {
  final Dio dio;

  SupportContactService(this.dio);

  /// Returns the support phone number, or null when none is configured.
  Future<String?> fetchSupportNumber() async {
    final res = await dio.get('/public/support/contact');
    final data = res.data;

    if (data is Map) {
      final phone = data['phoneNumber'];
      if (phone is String && phone.trim().isNotEmpty) {
        return phone.trim();
      }
    }
    return null;
  }
}
