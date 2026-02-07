import 'dart:io';
import 'package:dio/dio.dart';

class DioErrorMapper {
  static String toUserMessage(Object error) {
    if (error is! DioException)
      return "Something went wrong. Please try again.";

    final e = error;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return "Connection timed out. Try again.";
    }

    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return "Can’t reach the server. Check your internet and try again.";
    }

    final status = e.response?.statusCode;
    if (status != null) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = (data['message'] ?? data['error'] ?? '').toString().trim();
        if (msg.isNotEmpty) return msg;
      }

      if (status >= 500) return "Server is having issues. Try again later.";
      if (status == 401) return "Session expired. Please login again.";
      if (status == 403) return "You don’t have permission to do that.";
      if (status == 404) return "Not found.";
      return "Request failed ($status). Please try again.";
    }

    return "Something went wrong. Please try again.";
  }
}
