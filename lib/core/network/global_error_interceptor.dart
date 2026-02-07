import 'package:dio/dio.dart';
import 'server_status_controller.dart';

class GlobalErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sc = response.statusCode;
    if (sc != null && sc < 500) {
      ServerStatusController.markOk();
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final silent = err.requestOptions.extra['silent'] == true;
    if (!silent) {
      final status = err.response?.statusCode;

      final isServerDown = err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          (status != null && status >= 500);

      if (isServerDown) {
        // ✅ start 15s waiting (banner only), then popup if still down
        ServerStatusController.markDownCandidate();
      }
    }

    super.onError(err, handler);
  }
}
