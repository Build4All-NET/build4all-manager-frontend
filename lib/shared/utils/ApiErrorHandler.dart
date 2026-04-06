import '../../core/network/dio_error_mapper.dart';

class ApiErrorHandler {
  static String message(Object error) {
    return DioErrorMapper.toUserMessage(error);
  }
}