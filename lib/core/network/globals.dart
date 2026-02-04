// lib/core/network/globals.dart
library;

import 'package:dio/dio.dart';


// Shared HTTP client (set once in main()).
Dio? appDio;

//  Base API root is required after main() sets it, so make it non-nullable.
late String appServerRoot; // e.g. "http://host:8080/api"

// Multiple token aliases so old/new code both work.
String? authToken;
String? token;
String? userToken;
String? Token;


// Read a token safely (picks the first non-empty).
String readAuthToken() {
  return (authToken ?? token ?? userToken ?? Token ?? '').toString();
}

// Root without trailing `/api`.
String serverRootNoApi() {
  final base = appServerRoot;
  return base.replaceFirst(RegExp(r'/api/?$'), '');
}

// Ensure a Dio instance exists.
Dio dio() {
  return appDio ??= Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 1),
    ),
  );
}

/// NEW: convenience to configure the shared Dio with a baseUrl.
void makeDefaultDio(String baseUrl) {
  appDio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
